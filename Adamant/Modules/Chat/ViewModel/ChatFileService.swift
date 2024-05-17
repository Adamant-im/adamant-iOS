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
import FilesStorageKit

protocol ChatFileProtocol {
    var downloadingFiles: [String] { get }
    var uploadingFiles: [String] { get }
    
    var updateFileFields: PassthroughSubject<(
        id: String,
        newId: String?,
        fileNonce: String?,
        preview: UIImage?,
        needUpdatePreview: Bool,
        cached: Bool?,
        downloading: Bool?,
        uploading: Bool?
    ), Never> {
        get
    }
    
    func sendFile(
        text: String?,
        chatroom: Chatroom?,
        filesPicked: [FileResult]?,
        replyMessage: MessageModel?,
        saveEncrypted: Bool
    ) async throws
    
    func downloadFile(
        file: ChatFile,
        chatroom: Chatroom?,
        saveEncrypted: Bool
    ) async throws
    
    func autoDownload(
        file: ChatFile,
        chatroom: Chatroom?,
        havePartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async
    
    func getDecodedData(
        file: FilesStorageKit.File,
        nonce: String,
        chatroom: Chatroom?
    ) throws -> Data
}

final class ChatFileService: ChatFileProtocol {
    typealias UploadResult = (decodedData: Data, encodedData: Data, nonce: String, cid: String)
    
    // MARK: Dependencies
    
    private let accountService: AccountService
    private let filesStorage: FilesStorageProtocol
    private let chatsProvider: ChatsProvider
    private let filesNetworkManager: FilesNetworkManagerProtocol
    private let adamantCore: AdamantCore
    
    @Atomic private var downloadingFilesIDsArray: [String] = []
    @Atomic private var uploadingFilesIDsArray: [String] = []
    @Atomic private var ignoreFilesIDsArray: [String] = []
    @Atomic private var busyFilesIDs: [String] = []
    @Atomic private var fileDownloadAttemptsCount: [String: Int] = [:]

    private var subscriptions = Set<AnyCancellable>()
    private let maxDownloadAttemptsCount = 3
        
    var uploadingFiles: [String] {
        $uploadingFilesIDsArray.wrappedValue
    }
    
    var downloadingFiles: [String] {
        $downloadingFilesIDsArray.wrappedValue
    }
    
    let updateFileFields = ObservableSender<(
        id: String,
        newId: String?,
        fileNonce: String?,
        preview: UIImage?,
        needUpdatePreview: Bool,
        cached: Bool?,
        downloading: Bool?,
        uploading: Bool?
    )>()
    
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
        replyMessage: MessageModel?,
        saveEncrypted: Bool
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
            .init(
                id: $0.url.absoluteString,
                size: $0.size,
                nonce: .empty,
                name: $0.name,
                type: $0.extenstion,
                preview: $0.previewUrl.map { 
                    RichMessageFile.Preview(
                        id: $0.absoluteString,
                        nonce: .empty,
                        extension: .empty
                    )
                },
                resolution: $0.resolution
            )
        }
        
        let messageLocally: AdamantMessage
        
        if let replyMessage = replyMessage {
            messageLocally = .richMessage(
                payload: RichFileReply(
                    replyto_id: replyMessage.id,
                    reply_message: RichMessageFile(
                        files: richFiles,
                        storage: .init(id: storageProtocol.rawValue),
                        comment: text
                    )
                )
            )
        } else {
            messageLocally = .richMessage(
                payload: RichMessageFile(
                    files: richFiles,
                    storage: .init(id: storageProtocol.rawValue),
                    comment: text
                )
            )
        }
        
        for url in files.compactMap({ $0.previewUrl }) {
            filesStorage.cacheTemporaryFile(
                url: url,
                isEncrypted: false,
                fileType: .image,
                isPreview: true
            )
        }
        
        let txLocally = try await chatsProvider.sendFileMessageLocally(
            messageLocally,
            recipientId: partnerAddress,
            from: chatroom
        )
        
        richFiles.forEach { file in
            $uploadingFilesIDsArray.mutate { $0.append(file.id) }
            sendUpdate(for: [file.id], downloading: nil, uploading: true)
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
                    fileExtension: file.extenstion ?? .empty,
                    url: file.url,
                    decodedData: result.file.decodedData,
                    encodedData: result.file.encodedData,
                    ownerId: ownerId,
                    recipientId: partnerAddress,
                    saveEncrypted: saveEncrypted,
                    fileType: file.type, 
                    isPreview: false
                )
                
                var preview: UIImage?
                
                if let previewUrl = file.previewUrl,
                   let previewResult = result.preview {
                    try filesStorage.cacheFile(
                        id: previewResult.cid,
                        fileExtension: file.previewExtension ?? .empty,
                        url: previewUrl,
                        decodedData: previewResult.decodedData,
                        encodedData: previewResult.encodedData,
                        ownerId: ownerId,
                        recipientId: partnerAddress,
                        saveEncrypted: saveEncrypted,
                        fileType: .image,
                        isPreview: true
                    )
                    
                    preview = filesStorage.getPreview(for: previewResult.cid)
                }
                
                let oldId = file.url.absoluteString
                $uploadingFilesIDsArray.mutate {
                    $0.removeAll(where: { $0 == oldId })
                }
                let cached = filesStorage.isCachedLocally(result.file.cid)
                
                updateFileFields.send((
                    id: oldId,
                    newId: result.file.cid,
                    fileNonce: result.file.nonce,
                    preview: preview,
                    needUpdatePreview: true,
                    cached: cached,
                    downloading: nil,
                    uploading: false
                ))
                
                var previewDTO: RichMessageFile.Preview?
                if let cid = result.preview?.cid,
                   let nonce = result.preview?.nonce {
                    previewDTO = .init(
                        id: cid,
                        nonce: nonce,
                        extension: file.previewExtension
                    )
                }
                
                if let index = richFiles.firstIndex(
                    where: { $0.id == oldId }
                ) {
                    richFiles[index].id = result.file.cid
                    richFiles[index].nonce = result.file.nonce
                    richFiles[index].preview = previewDTO
                }
            }
            
            let message: AdamantMessage
            
            if let replyMessage = replyMessage {
                message = .richMessage(
                    payload: RichFileReply(
                        replyto_id: replyMessage.id,
                        reply_message: RichMessageFile(
                            files: richFiles,
                            storage: .init(id: NetworkFileProtocolType.ipfs.rawValue),
                            comment: text
                        )
                    )
                )
            } else {
                message = .richMessage(
                    payload: RichMessageFile(
                        files: richFiles,
                        storage: .init(id: NetworkFileProtocolType.ipfs.rawValue),
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
                $uploadingFilesIDsArray.mutate {
                    $0.removeAll(where: { $0 == file.id })
                }
                sendUpdate(for: [file.id], downloading: nil, uploading: false)
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
        chatroom: Chatroom?,
        saveEncrypted: Bool
    ) async throws {
        try await downloadFile(
            file: file,
            chatroom: chatroom,
            shouldDownloadOriginalFile: true,
            shouldDownloadPreviewFile: true,
            saveEncrypted: saveEncrypted
        )
    }
    
    func autoDownload(
        file: ChatFile,
        chatroom: Chatroom?,
        havePartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async {
        guard !downloadingFiles.contains(file.file.id),
              !$ignoreFilesIDsArray.wrappedValue.contains(file.file.id),
              !$busyFilesIDs.wrappedValue.contains(file.file.id)
        else {
            return
        }
        
        defer {
            $busyFilesIDs.mutate { $0.removeAll(where: { $0 == file.file.id }) }
        }
        
        $busyFilesIDs.mutate { $0.append(file.file.id) }
        
        await handleAutoDownload(
            file: file,
            chatroom: chatroom,
            havePartnerName: havePartnerName,
            previewDownloadPolicy: previewDownloadPolicy,
            fullMediaDownloadPolicy: fullMediaDownloadPolicy,
            saveEncrypted: saveEncrypted
        )
    }
    
    func getDecodedData(
        file: FilesStorageKit.File,
        nonce: String,
        chatroom: Chatroom?
    ) throws -> Data {
        guard let keyPair = accountService.keypair else {
            throw FileManagerError.cantDecryptFile
        }
        
        let data = try Data(contentsOf: file.url)
        
        guard file.isEncrypted else {
            return data
        }
        
        guard let decodedData = adamantCore.decodeData(
            data,
            rawNonce: nonce,
            senderPublicKey: chatroom?.partner?.publicKey ?? .empty,
            privateKey: keyPair.privateKey
        ) else {
            throw FileManagerError.cantDecryptFile
        }
        
        return decodedData
    }
}

private extension ChatFileService {
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantReachabilityMonitor.reachabilityChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                let connection = data.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool
                
                guard connection == true else { return }
                self?.ignoreFilesIDsArray.removeAll()
            }
            .store(in: &subscriptions)
    }
}

private extension ChatFileService {
    func handleAutoDownload(
        file: ChatFile,
        chatroom: Chatroom?,
        havePartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async {
        let shouldDownloadPreviewFile = shoudDownloadPreview(
            file: file,
            previewDownloadPolicy: previewDownloadPolicy,
            havePartnerName: havePartnerName
        )
        
        let shouldDownloadOriginalFile = shoudDownloadOriginal(
            file: file,
            fullMediaDownloadPolicy: fullMediaDownloadPolicy,
            havePartnerName: havePartnerName
        )
        
        guard shouldDownloadOriginalFile || shouldDownloadPreviewFile else {
            cacheFileToMemoryIfNeeded(file: file, chatroom: chatroom)
            return
        }
        
        do {
            try await downloadFile(
                file: file,
                chatroom: chatroom,
                shouldDownloadOriginalFile: shouldDownloadOriginalFile,
                shouldDownloadPreviewFile: shouldDownloadPreviewFile,
                saveEncrypted: saveEncrypted
            )
        } catch {
            await handleDownloadError(
                file: file,
                chatroom: chatroom,
                havePartnerName: havePartnerName,
                previewDownloadPolicy: previewDownloadPolicy,
                fullMediaDownloadPolicy: fullMediaDownloadPolicy,
                saveEncrypted: saveEncrypted
            )
        }
    }
    
    func handleDownloadError(
        file: ChatFile,
        chatroom: Chatroom?,
        havePartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async {
        let count = $fileDownloadAttemptsCount.wrappedValue[file.file.id] ?? .zero
        
        guard count < maxDownloadAttemptsCount else {
            $ignoreFilesIDsArray.mutate { $0.append(file.file.id) }
            return
        }
        
        $fileDownloadAttemptsCount.mutate { $0[file.file.id] = count + 1 }
        
        await handleAutoDownload(
            file: file,
            chatroom: chatroom,
            havePartnerName: havePartnerName,
            previewDownloadPolicy: previewDownloadPolicy,
            fullMediaDownloadPolicy: fullMediaDownloadPolicy,
            saveEncrypted: saveEncrypted
        )
    }
    
    func cacheFileToMemoryIfNeeded(
        file: ChatFile,
        chatroom: Chatroom?
    ) {
        guard let id = file.file.preview?.id,
              let nonce = file.file.preview?.nonce,
              let fileDTO = try? filesStorage.getFile(with: id),
              fileDTO.isPreview,
              filesStorage.isCachedLocally(id),
              !filesStorage.isCachedInMemory(id),
              let image = try? cacheFileToMemory(
                id: id,
                file: fileDTO,
                nonce: nonce,
                chatroom: chatroom
              )
        else {
            return
        }
        
        updateFileFields.send((
            id: file.file.id,
            newId: nil,
            fileNonce: nil,
            preview: image,
            needUpdatePreview: true,
            cached: nil,
            downloading: nil,
            uploading: nil
        ))
    }
    
    func cacheFileToMemory(
        id: String,
        file: FilesStorageKit.File,
        nonce: String,
        chatroom: Chatroom?
    ) throws -> UIImage? {
        let data = try Data(contentsOf: file.url)
        
        guard file.isEncrypted else {
            return filesStorage.cacheImageToMemoryIfNeeded(id: id, data: data)
        }
        
        let decodedData = try getDecodedData(
            file: file,
            nonce: nonce,
            chatroom: chatroom
        )
        
        return filesStorage.cacheImageToMemoryIfNeeded(id: id, data: decodedData)
    }
    
    func downloadFile(
        file: ChatFile,
        chatroom: Chatroom?,
        shouldDownloadOriginalFile: Bool,
        shouldDownloadPreviewFile: Bool,
        saveEncrypted: Bool
    ) async throws {
        guard let keyPair = accountService.keypair,
              let ownerId = accountService.account?.address,
              let recipientId = chatroom?.partner?.address,
              NetworkFileProtocolType(rawValue: file.storage) != nil,
              (shouldDownloadOriginalFile || shouldDownloadPreviewFile),
              !downloadingFiles.contains(file.file.id)
        else { return }
        
        guard !file.file.id.isEmpty,
              !file.file.nonce.isEmpty
        else {
            throw FileManagerError.cantDownloadFile
        }
        
        defer {
            $downloadingFilesIDsArray.mutate { $0.removeAll(where: { $0 == file.file.id }) }
            sendUpdate(for: [file.file.id], downloading: false, uploading: nil)
        }
        
        $downloadingFilesIDsArray.mutate { $0.append(file.file.id) }
        sendUpdate(for: [file.file.id], downloading: true, uploading: nil)
        
        if let previewDTO = file.file.preview {
            if shouldDownloadPreviewFile,
               !filesStorage.isCachedLocally(previewDTO.id) {
                try await downloadAndCacheFile(
                    id: previewDTO.id,
                    nonce: previewDTO.nonce,
                    storage: file.storage,
                    publicKey: chatroom?.partner?.publicKey ?? .empty,
                    privateKey: keyPair.privateKey,
                    ownerId: ownerId,
                    recipientId: recipientId,
                    saveEncrypted: saveEncrypted,
                    fileType: .image,
                    fileExtension: previewDTO.extension ?? .empty,
                    isPreview: true
                )
                
                let preview = filesStorage.getPreview(for: previewDTO.id)
                
                updateFileFields.send((
                    id: file.file.id,
                    newId: nil,
                    fileNonce: nil,
                    preview: preview,
                    needUpdatePreview: true,
                    cached: nil,
                    downloading: nil,
                    uploading: nil
                ))
            } else if !filesStorage.isCachedInMemory(previewDTO.id) {
                cacheFileToMemoryIfNeeded(file: file, chatroom: chatroom)
            }
        }
        
        if shouldDownloadOriginalFile,
           !filesStorage.isCachedLocally(file.file.id) {
            try await downloadAndCacheFile(
                id: file.file.id,
                nonce: file.nonce,
                storage: file.storage,
                publicKey: chatroom?.partner?.publicKey ?? .empty,
                privateKey: keyPair.privateKey,
                ownerId: ownerId,
                recipientId: recipientId,
                saveEncrypted: saveEncrypted,
                fileType: file.fileType,
                fileExtension: file.file.type ?? .empty,
                isPreview: false
            )
            
            let cached = filesStorage.isCachedLocally(file.file.id)
            
            updateFileFields.send((
                id: file.file.id,
                newId: nil,
                fileNonce: nil,
                preview: nil,
                needUpdatePreview: false,
                cached: cached,
                downloading: nil,
                uploading: nil
            ))
        }
    }
    
    func downloadAndCacheFile(
        id: String,
        nonce: String,
        storage: String,
        publicKey: String,
        privateKey: String,
        ownerId: String,
        recipientId: String,
        saveEncrypted: Bool,
        fileType: FileType,
        fileExtension: String,
        isPreview: Bool
    ) async throws {
        let result = try await downloadFile(
            id: id,
            storage: storage,
            senderPublicKey: publicKey,
            recipientPrivateKey: privateKey,
            nonce: nonce,
            saveEncrypted: saveEncrypted
        )
        
        try filesStorage.cacheFile(
            id: id,
            fileExtension: fileExtension,
            url: nil,
            decodedData: result.decodedData,
            encodedData: result.encodedData,
            ownerId: ownerId,
            recipientId: recipientId,
            saveEncrypted: saveEncrypted,
            fileType: fileType,
            isPreview: isPreview
        )
    }
    
    func shoudDownloadOriginal(
        file: ChatFile,
        fullMediaDownloadPolicy: DownloadPolicy,
        havePartnerName: Bool
    ) -> Bool {
        let isMedia = file.fileType == .image || file.fileType == .video
        let shouldDownloadOriginalFile: Bool
        switch fullMediaDownloadPolicy {
        case .nobody:
            shouldDownloadOriginalFile = false
        case .everybody:
            shouldDownloadOriginalFile = !filesStorage.isCachedLocally(file.file.id) && isMedia
            ? true
            : false
        case .contacts:
            shouldDownloadOriginalFile = !filesStorage.isCachedLocally(file.file.id) && isMedia
            ? havePartnerName
            : false
        }
        
        return shouldDownloadOriginalFile
    }
    
    func shoudDownloadPreview(
        file: ChatFile,
        previewDownloadPolicy: DownloadPolicy,
        havePartnerName: Bool
    ) -> Bool {
        let shouldDownloadPreviewFile: Bool
        switch previewDownloadPolicy {
        case .nobody:
            shouldDownloadPreviewFile = false
        case .everybody:
            shouldDownloadPreviewFile = needsPreviewDownload(file: file)
            ? true
            : false
        case .contacts:
            shouldDownloadPreviewFile = needsPreviewDownload(file: file)
            ? havePartnerName
            : false
        }
        
        return shouldDownloadPreviewFile
    }
    
    func needsPreviewDownload(file: ChatFile) -> Bool {
        if let previewId = file.file.preview?.id,
           file.file.preview?.nonce != nil,
           !$ignoreFilesIDsArray.wrappedValue.contains(previewId),
           !filesStorage.isCachedLocally(previewId) {
            return true
        }
        
        return false
    }
    
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
    ) async throws -> UploadResult {
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
        return (data, encodedData, nonce, cid)
    }
    
    func downloadFile(
        id: String,
        storage: String,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String,
        saveEncrypted: Bool
    ) async throws -> (decodedData: Data, encodedData: Data) {
        let encodedData = try await filesNetworkManager.downloadFile(id, type: storage)
        
        guard let decodedData = adamantCore.decodeData(
            encodedData,
            rawNonce: nonce,
            senderPublicKey: senderPublicKey,
            privateKey: recipientPrivateKey
        ) else {
            throw FileManagerError.cantDecryptFile
        }
        
        return (decodedData, encodedData)
    }
}

private extension ChatFileService {
    func sendUpdate(for files: [String], downloading: Bool?, uploading: Bool?) {
        files.forEach { id in
            updateFileFields.send((
                id: id,
                newId: nil,
                fileNonce: nil,
                preview: nil,
                needUpdatePreview: false,
                cached: nil,
                downloading: downloading,
                uploading: uploading
            ))
        }
    }
}
