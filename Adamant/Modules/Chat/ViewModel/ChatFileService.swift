//
//  ChatFileService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 01.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import FilesNetworkManagerKit
import UIKit
import Combine

protocol ChatFileProtocol {
    var downloadingFilesIDs: Published<[String]>.Publisher {
        get
    }
    
    var uploadingFilesIDs: Published<[String]>.Publisher {
        get
    }
    
    var updateFileFields: PassthroughSubject<(id: String, newId: String?, preview: UIImage?, cached: Bool), Never> {
        get
    }
    
    func sendFile(
        text: String?,
        chatroom: Chatroom?,
        filesPicked: [FileResult]?,
        replyMessage: MessageModel?
    ) async throws
    
    func downloadFile(
        file: ChatFile,
        isFromCurrentSender: Bool,
        chatroom: Chatroom?
    ) async throws
    
    func downloadPreviewIfNeeded(
        messageId: String,
        file: ChatFile,
        isFromCurrentSender: Bool,
        chatroom: Chatroom?
    )
}

final class ChatFileService: ChatFileProtocol {
    // MARK: Dependencies
    
    private let accountService: AccountService
    private let filesStorage: FilesStorageProtocol
    private let chatsProvider: ChatsProvider
    
    @Published private var downloadingFilesIDsArray: [String] = []
    @Published private var uploadingFilesIDsArray: [String] = []

    private var ignoreFilesIDsArray: [String] = []
    private var subscriptions = Set<AnyCancellable>()
    
    var downloadingFilesIDs: Published<[String]>.Publisher {
        $downloadingFilesIDsArray
    }
    
    var uploadingFilesIDs: Published<[String]>.Publisher {
        $uploadingFilesIDsArray
    }
    
    let updateFileFields = ObservableSender<(id: String, newId: String?, preview: UIImage?, cached: Bool)>()
    
    init(
        accountService: AccountService,
        filesStorage: FilesStorageProtocol,
        chatsProvider: ChatsProvider
    ) {
        self.accountService = accountService
        self.filesStorage = filesStorage
        self.chatsProvider = chatsProvider
        
        addObservers()
    }
    
    func sendFile(
        text: String?,
        chatroom: Chatroom?,
        filesPicked: [FileResult]?,
        replyMessage: MessageModel?
    ) async throws {
        guard let partnerAddress = chatroom?.partner?.address,
              let files = filesPicked,
              let keyPair = accountService.keypair,
              let ownerId = accountService.account?.address
        else { return }
        
        guard chatroom?.partner?.isDummy != true else {
            return
        }
        
        let replyMessage = replyMessage
        
        var richFiles: [RichMessageFile.File] = files.compactMap {
            RichMessageFile.File.init(
                file_id: $0.url.absoluteString,
                file_type: $0.extenstion,
                file_size: $0.size,
                preview_id: $0.previewUrl?.absoluteString,
                preview_nonce: nil,
                file_name: $0.name,
                nonce: .empty,
                file_resolution: $0.resolution
            )
        }
        
        let messageLocally: AdamantMessage
        
        if let replyMessage = replyMessage {
            messageLocally = .richMessage(
                payload: RichFileReply(
                    replyto_id: replyMessage.id,
                    reply_message: RichMessageFile(
                        files: richFiles,
                        storage: NetworkFileProtocolType.uploadCareApi.rawValue,
                        comment: text
                    )
                )
            )
        } else {
            messageLocally = .richMessage(
                payload: RichMessageFile(
                    files: richFiles,
                    storage: NetworkFileProtocolType.uploadCareApi.rawValue,
                    comment: text
                )
            )
        }
        
        let txLocally = try await chatsProvider.sendFileMessageLocally(
            messageLocally,
            recipientId: partnerAddress,
            from: chatroom
        )
        
        richFiles.forEach { file in
            uploadingFilesIDsArray.append(file.file_id)
        }
        
        do {
            for file in files {
                let result = try await filesStorage.uploadFile(
                    file,
                    recipientPublicKey: chatroom?.partner?.publicKey ?? "",
                    senderPrivateKey: keyPair.privateKey,
                    ownerId: ownerId,
                    recipientId: partnerAddress
                )
                
                let oldId = file.url.absoluteString
                uploadingFilesIDsArray.removeAll(where: { $0 == oldId })
                
                let previewID: String
                if let id = result.idPreview {
                    previewID = id
                } else {
                    previewID = result.id
                }
                
                let preview = filesStorage.getPreview(
                    for: previewID,
                    type: file.extenstion ?? ""
                )
                
                let cached = filesStorage.isCached(result.id)
                
                updateFileFields.send((
                    id: oldId,
                    newId: result.id,
                    preview: preview,
                    cached: cached
                ))
                
                if let index = richFiles.firstIndex(
                    where: { $0.file_id == oldId }
                ) {
                    richFiles[index].file_id = result.id
                    richFiles[index].nonce = result.nonce
                    richFiles[index].preview_id = result.idPreview
                    richFiles[index].preview_nonce = result.noncePreview
                }
            }
            
            let message: AdamantMessage
            
            if let replyMessage = replyMessage {
                message = .richMessage(
                    payload: RichFileReply(
                        replyto_id: replyMessage.id,
                        reply_message: RichMessageFile(
                            files: richFiles,
                            storage: NetworkFileProtocolType.uploadCareApi.rawValue,
                            comment: text
                        )
                    )
                )
            } else {
                message = .richMessage(
                    payload: RichMessageFile(
                        files: richFiles,
                        storage: NetworkFileProtocolType.uploadCareApi.rawValue,
                        comment: text
                    )
                )
            }
            
            _ = try await chatsProvider.sendFileMessage(
                message,
                recipientId: partnerAddress,
                transactionLocaly: txLocally.tx,
                context: txLocally.context,
                from: chatroom
            )
        } catch {
            richFiles.forEach { file in
                uploadingFilesIDsArray.removeAll(where: { $0 == file.file_id })
            }
            
            try? await chatsProvider.setTxMessageAsFailed(
                transactionLocaly: txLocally.tx,
                context: txLocally.context
            )
            
            throw error
        }
    }
    
    func downloadFile(
        file: ChatFile,
        isFromCurrentSender: Bool,
        chatroom: Chatroom?
    ) async throws {
        guard let keyPair = accountService.keypair,
              let ownerId = accountService.account?.address,
              let recipientId = chatroom?.partner?.address
        else { return }
        
        defer {
            downloadingFilesIDsArray.removeAll(where: { $0 == file.file.file_id })
        }
        downloadingFilesIDsArray.append(file.file.file_id)
        
        try await filesStorage.downloadFile(
            id: file.file.file_id,
            storage: file.storage,
            fileType: file.file.file_type ?? .empty,
            senderPublicKey: chatroom?.partner?.publicKey ?? .empty,
            recipientPrivateKey: keyPair.privateKey,
            ownerId: ownerId,
            recipientId: recipientId,
            nonce: file.nonce,
            previewId: nil,
            previewNonce: nil
        )
        
        let previewID: String
        if let id = file.file.preview_id {
            previewID = id
        } else {
            previewID = file.file.file_id
        }
        
        let preview = filesStorage.getPreview(
            for: previewID,
            type: file.file.file_type ?? ""
        )
        
        let cached = filesStorage.isCached(file.file.file_id)
        
        updateFileFields.send((
            id: file.file.file_id,
            newId: nil,
            preview: preview,
            cached: cached
        ))
    }
    
    func downloadPreviewIfNeeded(
        messageId: String,
        file: ChatFile,
        isFromCurrentSender: Bool,
        chatroom: Chatroom?
    ) {
        guard let keyPair = accountService.keypair,
              !downloadingFilesIDsArray.contains(file.file.file_id),
              !ignoreFilesIDsArray.contains(file.file.file_id),
              let previewId = file.file.preview_id,
              let previewNonce = file.file.preview_nonce,
              !filesStorage.isCached(previewId),
              let ownerId = accountService.account?.address,
              let recipientId = chatroom?.partner?.address
        else { return }
        
        downloadingFilesIDsArray.append(file.file.file_id)
        
        Task {
            defer {
                downloadingFilesIDsArray.removeAll(where: { $0 == file.file.file_id })
            }
            
            do {
                try await filesStorage.cachePreview(
                    storage: file.storage,
                    fileType: file.file.file_type ?? .empty,
                    senderPublicKey: chatroom?.partner?.publicKey ?? .empty,
                    recipientPrivateKey: keyPair.privateKey,
                    ownerId: ownerId,
                    recipientId: recipientId,
                    previewId: previewId,
                    previewNonce: previewNonce
                )
                
                let preview = filesStorage.getPreview(
                    for: previewId,
                    type: file.file.file_type ?? .empty
                )
                
                let cached = filesStorage.isCached(file.file.file_id)
                
                updateFileFields.send((
                    id: file.file.file_id,
                    newId: nil,
                    preview: preview,
                    cached: cached
                ))
            } catch {
                ignoreFilesIDsArray.append(file.file.file_id)
            }
        }
    }
}

private extension ChatFileService {
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantReachabilityMonitor.reachabilityChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] data in
                let connection = data.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool
                
                if connection == true {
                    self?.ignoreFilesIDsArray.removeAll()
                }
            }
            .store(in: &subscriptions)
    }
}
