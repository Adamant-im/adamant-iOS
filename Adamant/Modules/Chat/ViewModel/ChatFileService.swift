//
//  ChatFileService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 01.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
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
    typealias UploadResult = (data: Data, nonce: String, cid: String)
    
    // MARK: Dependencies
    
    private let accountService: AccountService
    private let filesStorage: FilesStorageProtocol
    private let chatsProvider: ChatsProvider
    private let filesNetworkManager: FilesNetworkManagerProtocol
    private let adamantCore: AdamantCore
    
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
        chatsProvider: ChatsProvider,
        filesNetworkManager: FilesNetworkManagerProtocol,
        adamantCore: AdamantCore
    ) {
        self.accountService = accountService
        self.filesStorage = filesStorage
        self.chatsProvider = chatsProvider
        self.filesNetworkManager = filesNetworkManager
        self.adamantCore = adamantCore
        
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
              let ownerId = accountService.account?.address,
              chatroom?.partner?.isDummy != true
        else { return }
        
        let storageProtocol = NetworkFileProtocolType.ipfs
        
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
                        storage: storageProtocol.rawValue,
                        comment: text
                    )
                )
            )
        } else {
            messageLocally = .richMessage(
                payload: RichMessageFile(
                    files: richFiles,
                    storage: storageProtocol.rawValue,
                    comment: text
                )
            )
        }
        
        for url in files.compactMap({ $0.previewUrl }) {
            filesStorage.cacheTemporaryFile(url: url)
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
                let result = try await uploadFileToServer(
                    file: file,
                    recipientPublicKey: chatroom?.partner?.publicKey ?? .empty,
                    senderPrivateKey: keyPair.privateKey,
                    storageProtocol: storageProtocol
                )
                
                try filesStorage.cacheFile(
                    id: result.file.cid,
                    url: file.url,
                    ownerId: ownerId,
                    recipientId: partnerAddress
                )
                
                if let previewUrl = file.previewUrl,
                   let previewId = result.preview?.cid {
                    try filesStorage.cacheFile(
                        id: previewId,
                        url: previewUrl,
                        ownerId: ownerId,
                        recipientId: partnerAddress
                    )
                }
                
                let oldId = file.url.absoluteString
                uploadingFilesIDsArray.removeAll(where: { $0 == oldId })
                
                let previewID: String
                if let id = result.preview?.cid {
                    previewID = id
                } else {
                    previewID = result.file.cid
                }
                
                let preview = filesStorage.getPreview(
                    for: previewID,
                    type: file.extenstion ?? ""
                )
                
                let cached = filesStorage.isCached(result.file.cid)
                
                updateFileFields.send((
                    id: oldId,
                    newId: result.file.cid,
                    preview: preview,
                    cached: cached
                ))
                
                if let index = richFiles.firstIndex(
                    where: { $0.file_id == oldId }
                ) {
                    richFiles[index].file_id = result.file.cid
                    richFiles[index].nonce = result.file.nonce
                    richFiles[index].preview_id = result.preview?.cid
                    richFiles[index].preview_nonce = result.preview?.nonce
                }
            }
            
            let message: AdamantMessage
            
            if let replyMessage = replyMessage {
                message = .richMessage(
                    payload: RichFileReply(
                        replyto_id: replyMessage.id,
                        reply_message: RichMessageFile(
                            files: richFiles,
                            storage: NetworkFileProtocolType.ipfs.rawValue,
                            comment: text
                        )
                    )
                )
            } else {
                message = .richMessage(
                    payload: RichMessageFile(
                        files: richFiles,
                        storage: NetworkFileProtocolType.ipfs.rawValue,
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
        
        let data = try await downloadFile(
            id: file.file.file_id,
            storage: file.storage,
            senderPublicKey: chatroom?.partner?.publicKey ?? .empty,
            recipientPrivateKey: keyPair.privateKey,
            nonce: file.nonce
        )
        
        try filesStorage.cacheFile(
            id: file.file.file_id,
            data: data,
            ownerId: ownerId,
            recipientId: recipientId
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
              let recipientId = chatroom?.partner?.address,
              NetworkFileProtocolType(rawValue: file.storage) != nil
        else { return }
        
        downloadingFilesIDsArray.append(file.file.file_id)
        
        Task {
            defer {
                downloadingFilesIDsArray.removeAll(where: { $0 == file.file.file_id })
            }
            
            do {
                let data = try await downloadFile(
                    id: previewId,
                    storage: file.storage,
                    senderPublicKey: chatroom?.partner?.publicKey ?? .empty,
                    recipientPrivateKey: keyPair.privateKey,
                    nonce: previewNonce
                )
                
                try filesStorage.cacheFile(
                    id: previewId,
                    data: data,
                    ownerId: ownerId,
                    recipientId: recipientId
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

private extension ChatFileService {
    func uploadFileToServer(
        file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String,
        storageProtocol: NetworkFileProtocolType
    ) async throws -> (file: UploadResult, preview: UploadResult?) {
        let result = try await uploadFile(
            url: file.url,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey,
            storageProtocol: storageProtocol
        )
        
        var preview: UploadResult?
        
        if let url = file.previewUrl {
            preview = try? await uploadFile(
                url: url,
                recipientPublicKey: recipientPublicKey,
                senderPrivateKey: senderPrivateKey,
                storageProtocol: storageProtocol
            )
        }
        
        return (result, preview)
    }
    
    func uploadFile(
        url: URL,
        recipientPublicKey: String,
        senderPrivateKey: String,
        storageProtocol: NetworkFileProtocolType
    ) async throws -> (data: Data, nonce: String, cid: String) {
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        _ = url.startAccessingSecurityScopedResource()
        
        let data = try Data(contentsOf: url)
        
        let encodedResult = adamantCore.encodeData(
            data,
            recipientPublicKey: recipientPublicKey,
            privateKey: senderPrivateKey
        )
        
        guard let encodedData = encodedResult?.data,
              let nonce = encodedResult?.nonce
        else {
            throw FileManagerError.cantEncryptFile
        }
        
        let cid = try await filesNetworkManager.uploadFiles(encodedData, type: storageProtocol)
        return (encodedData, nonce, cid)
    }
    
    func downloadFile(
        id: String,
        storage: String,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String
    ) async throws -> Data {
        let encodedData = try await filesNetworkManager.downloadFile(id, type: storage)
        
        guard let decodedData = adamantCore.decodeData(
            encodedData,
            rawNonce: nonce,
            senderPublicKey: senderPublicKey,
            privateKey: recipientPrivateKey
        )
        else {
            throw FileManagerError.cantDecryptFile
        }
        
        return decodedData
    }
}
