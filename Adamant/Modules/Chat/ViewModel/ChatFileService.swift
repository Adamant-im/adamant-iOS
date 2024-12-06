//
//  ChatFileService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 01.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import UIKit
import Combine
import FilesStorageKit
import CoreData

private struct FileUpload {
    let file: FileResult
    var isUploaded: Bool
    var serverFileID: String?
    var fileNonce: String?
    var preview: RichMessageFile.Preview?
}

private struct FileMessage {
    var files: [FileUpload]
    var message: String?
    var txId: String?
}

@MainActor
final class ChatFileService: ChatFileProtocol, Sendable {
    typealias UploadResult = (decodedData: Data, encodedData: Data, nonce: String, cid: String)
    
    // MARK: Dependencies
    
    private let accountService: AccountService
    private let filesStorage: FilesStorageProtocol
    private let chatsProvider: ChatsProvider
    private let filesNetworkManager: FilesNetworkManagerProtocol
    private let adamantCore: AdamantCore
    
    private(set) var downloadingFiles: [String: DownloadStatus] = [:]
    private(set) var uploadingFiles: [String] = []
    private(set) var filesLoadingProgress: [String: Int] = [:]
    
    private var ignoreFilesIDsArray: [String] = []
    private var busyFilesIDs: [String] = []
    private var fileDownloadAttemptsCount: [String: Int] = [:]
    private var uploadingFilesDictionary: [String: FileMessage] = [:]
    private var previewDownloadsAttemps: [String: Int] = [:]
    private let _updateFileFields = ObservableSender<FileUpdateProperties>()
    
    private var subscriptions = Set<AnyCancellable>()
    private let maxDownloadAttemptsCount = 3
    private let maxDownloadPreivewAttemptsCount = 2
    
    var updateFileFields: AnyObservable<FileUpdateProperties> {
        _updateFileFields.eraseToAnyPublisher()
    }
    
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
        guard let filesPicked = filesPicked else { return }
        
        let files = filesPicked.map {
            FileUpload(
                file: $0,
                isUploaded: false,
                serverFileID: nil,
                fileNonce: nil,
                preview: nil
            )
        }
        
        let fileMessage = FileMessage.init(files: files)
        
        try await sendFile(
            text: text,
            chatroom: chatroom,
            fileMessage: fileMessage,
            replyMessage: replyMessage,
            saveEncrypted: saveEncrypted
        )
    }
    
    func resendMessage(
        with id: String,
        text: String?,
        chatroom: Chatroom?,
        replyMessage: MessageModel?,
        saveEncrypted: Bool
    ) async throws {
        guard let fileMessage = uploadingFilesDictionary[id] else { return }
        
        try await sendFile(
            text: text,
            chatroom: chatroom,
            fileMessage: fileMessage,
            replyMessage: replyMessage,
            saveEncrypted: saveEncrypted
        )
    }
    
    func downloadFile(
        file: ChatFile,
        chatroom: Chatroom?,
        saveEncrypted: Bool,
        previewDownloadAllowed: Bool,
        fullMediaDownloadAllowed: Bool
    ) async throws {
        let isCachedOriginal = filesStorage.isCachedLocally(file.file.id)
        let isCachedPreview = filesStorage.isCachedInMemory(file.file.preview?.id ?? .empty)
        
        try await downloadFile(
            file: file,
            chatroom: chatroom,
            shouldDownloadOriginalFile: !isCachedOriginal && fullMediaDownloadAllowed,
            shouldDownloadPreviewFile: !isCachedPreview && previewDownloadAllowed,
            saveEncrypted: saveEncrypted
        )
    }
    
    func autoDownload(
        file: ChatFile,
        chatroom: Chatroom?,
        hasPartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async {
        guard !downloadingFiles.keys.contains(file.file.id),
              !ignoreFilesIDsArray.contains(file.file.id),
              !busyFilesIDs.contains(file.file.id)
        else {
            return
        }
        
        defer {
            busyFilesIDs.removeAll { $0 == file.file.id }
        }
        
        busyFilesIDs.append(file.file.id)
        
        await handleAutoDownload(
            file: file,
            chatroom: chatroom,
            hasPartnerName: hasPartnerName,
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
    
    func isDownloadPreviewLimitReached(for fileId: String) -> Bool {
        let count = previewDownloadsAttemps[fileId] ?? .zero
        guard count < maxDownloadPreivewAttemptsCount else { return true }
        
        previewDownloadsAttemps[fileId] = count + 1
        return false
    }
    
    func isPreviewAutoDownloadAllowedByPolicy(
        hasPartnerName: Bool,
        isFromCurrentSender: Bool,
        downloadPolicy: DownloadPolicy
    ) -> Bool {
        switch downloadPolicy {
        case .everybody: true
        case .nobody: isFromCurrentSender
        case .contacts: hasPartnerName || isFromCurrentSender
        }
    }
    
    func isOriginalAutoDownloadAllowedByPolicy(
        hasPartnerName: Bool,
        isFromCurrentSender: Bool,
        downloadPolicy: DownloadPolicy
    ) -> Bool {
        switch downloadPolicy {
        case .everybody: true
        case .nobody: false
        case .contacts: hasPartnerName || isFromCurrentSender
        }
    }
}

private extension ChatFileService {
    func addObservers() {
        NotificationCenter.default
            .notifications(named: .AdamantReachabilityMonitor.reachabilityChanged)
            .sink { @MainActor [weak self] data in
                let connection = data.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool
                
                guard connection == true else { return }
                self?.ignoreFilesIDsArray.removeAll()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .Storage.storageClear)
            .sink { @MainActor [weak self] _ in
                self?.ignoreFilesIDsArray.removeAll()
                self?.filesLoadingProgress.removeAll()
                self?.fileDownloadAttemptsCount.removeAll()
            }
            .store(in: &subscriptions)
    }
}

private extension ChatFileService {
    func handleAutoDownload(
        file: ChatFile,
        chatroom: Chatroom?,
        hasPartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async {
        let shouldDownloadPreviewFile = shouldAutoDownloadPreview(
            file: file,
            previewDownloadPolicy: previewDownloadPolicy,
            hasPartnerName: hasPartnerName
        )
        
        let shouldDownloadOriginalFile = shouldAutoDownloadOriginal(
            file: file,
            fullMediaDownloadPolicy: fullMediaDownloadPolicy,
            hasPartnerName: hasPartnerName
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
                hasPartnerName: hasPartnerName,
                previewDownloadPolicy: previewDownloadPolicy,
                fullMediaDownloadPolicy: fullMediaDownloadPolicy,
                saveEncrypted: saveEncrypted
            )
        }
    }
    
    func handleDownloadError(
        file: ChatFile,
        chatroom: Chatroom?,
        hasPartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async {
        let count = fileDownloadAttemptsCount[file.file.id] ?? .zero
        
        guard count < maxDownloadAttemptsCount else {
            ignoreFilesIDsArray.append(file.file.id)
            return
        }
        
        fileDownloadAttemptsCount[file.file.id] = count + 1
        
        await handleAutoDownload(
            file: file,
            chatroom: chatroom,
            hasPartnerName: hasPartnerName,
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
              let fileDTO = try? filesStorage.getFile(with: id).get(),
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
        
        _updateFileFields.send(.init(
            id: file.file.id,
            newId: nil,
            fileNonce: nil,
            preview: .some(image),
            cached: nil,
            downloadStatus: nil,
            uploading: nil,
            progress: nil
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
              !downloadingFiles.keys.contains(file.file.id)
        else { return }
        
        guard !file.file.id.isEmpty,
              !file.file.nonce.isEmpty
        else {
            throw FileManagerError.cantDownloadFile
        }
        
        defer {
            downloadingFiles[file.file.id] = nil
            sendUpdate(
                for: [file.file.id],
                downloadStatus: .init(
                    isPreviewDownloading: false,
                    isOriginalDownloading: false
                ),
                uploading: nil
            )
        }
                
        let downloadFile = shouldDownloadOriginalFile
        && !filesStorage.isCachedLocally(file.file.id)
        
        let downloadPreview = file.file.preview != nil
        && shouldDownloadPreviewFile
        && !filesStorage.isCachedLocally(file.file.preview?.id ?? .empty)
        
        let downloadStatus: DownloadStatus = .init(
            isPreviewDownloading: downloadPreview,
            isOriginalDownloading: downloadFile
        )
        
        downloadingFiles[file.file.id] = downloadStatus

        // Here we start showing progress from the last saved value (fileProgressValue) instead of zero because in the UI we need to show progress when the download is frozen. We have N attempts to download, and the progress is overridden.
        // So we start from the last saved progress and override it with 'downloadProgress' upon successful start of the download.
        sendUpdate(
            for: [file.file.id],
            downloadStatus: .init(
                isPreviewDownloading: downloadPreview,
                isOriginalDownloading: downloadFile
            ),
            uploading: nil,
            progress: downloadFile 
                ? filesLoadingProgress[file.file.id] ?? .zero
                : nil
        )
        
        let totalProgress = Progress(totalUnitCount: 100)
        
        let (previewWeight, fileWeight) = getProgressWeights(
            downloadPreview: false,
            downloadFile: downloadFile
        )
        
        let previewProgress = Progress(totalUnitCount: previewWeight)
        totalProgress.addChild(previewProgress, withPendingUnitCount: previewWeight)
        
        let fileProgress = Progress(totalUnitCount: fileWeight)
        totalProgress.addChild(fileProgress, withPendingUnitCount: fileWeight)
        
        if let previewDTO = file.file.preview {
            if downloadPreview {
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
                    isPreview: true,
                    downloadProgress: { value in
                        previewProgress.completedUnitCount = Int64(value.fractionCompleted * Double(previewWeight))
                    }
                )
                
                let preview = filesStorage.getPreview(for: previewDTO.id)
                
                _updateFileFields.send(.init(
                    id: file.file.id,
                    newId: nil,
                    fileNonce: nil,
                    preview: .some(preview),
                    cached: nil,
                    downloadStatus: nil,
                    uploading: nil,
                    progress: nil
                ))
            } else if !filesStorage.isCachedInMemory(previewDTO.id) {
                cacheFileToMemoryIfNeeded(file: file, chatroom: chatroom)
            }
        }
        
        if downloadFile {
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
                fileExtension: file.file.extension ?? .empty,
                isPreview: false,
                downloadProgress: { @MainActor [weak self] value in
                    // TODO: COMEBACK
                    fileProgress.completedUnitCount = Int64(value.fractionCompleted * Double(fileWeight))
                    
                    self?.sendProgress(
                        for: file.file.id, 
                        progress: Int(totalProgress.fractionCompleted * 100)
                    )
                }
            )
            
            let cached = filesStorage.isCachedLocally(file.file.id)
            
            _updateFileFields.send(.init(
                id: file.file.id,
                newId: nil,
                fileNonce: nil,
                preview: nil,
                cached: cached,
                downloadStatus: nil,
                uploading: nil,
                progress: nil
            ))
        }
    }
    
    func getProgressWeights(
        downloadPreview: Bool,
        downloadFile: Bool
    ) -> (previewWeight: Int64, fileWeight: Int64) {
        var previewWeight: Int64 = .zero
        var fileWeight: Int64 = .zero
        
        if downloadPreview && downloadFile {
            previewWeight = 10
            fileWeight = 90
        } else if downloadPreview && !downloadFile {
            previewWeight = 100
            fileWeight = .zero
        } else if !downloadPreview && downloadFile {
            previewWeight = .zero
            fileWeight = 100
        }
        
        return (previewWeight, fileWeight)
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
        isPreview: Bool,
        downloadProgress: @escaping @Sendable (Progress) -> Void
    ) async throws {
        let result = try await downloadFile(
            id: id,
            storage: storage,
            senderPublicKey: publicKey,
            recipientPrivateKey: privateKey,
            nonce: nonce,
            saveEncrypted: saveEncrypted,
            downloadProgress: downloadProgress
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
    
    func shouldAutoDownloadOriginal(
        file: ChatFile,
        fullMediaDownloadPolicy: DownloadPolicy,
        hasPartnerName: Bool
    ) -> Bool {
        let isMedia = file.fileType == .image || file.fileType == .video
        let isCached = filesStorage.isCachedLocally(file.file.id)
        
        return isOriginalAutoDownloadAllowedByPolicy(
            hasPartnerName: hasPartnerName,
            isFromCurrentSender: file.isFromCurrentSender,
            downloadPolicy: fullMediaDownloadPolicy
        ) && !isCached && isMedia
    }
    
    func shouldAutoDownloadPreview(
        file: ChatFile,
        previewDownloadPolicy: DownloadPolicy,
        hasPartnerName: Bool
    ) -> Bool {
        guard
            let previewId = file.file.preview?.id,
            file.file.preview?.nonce != nil,
            !ignoreFilesIDsArray.contains(previewId),
            !filesStorage.isCachedLocally(previewId)
        else { return false }
        
        return isPreviewAutoDownloadAllowedByPolicy(
            hasPartnerName: hasPartnerName,
            isFromCurrentSender: file.isFromCurrentSender,
            downloadPolicy: previewDownloadPolicy
        )
    }
    
    func downloadFile(
        id: String,
        storage: String,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String,
        saveEncrypted: Bool,
        downloadProgress: @escaping @Sendable (Progress) -> Void
    ) async throws -> (decodedData: Data, encodedData: Data) {
        let encodedData = try await filesNetworkManager.downloadFile(
            id,
            type: storage,
            downloadProgress: downloadProgress
        ).get()
        
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
    func sendUpdate(
        for files: [String],
        downloadStatus: DownloadStatus?,
        uploading: Bool?,
        progress: Int? = nil
    ) {
        files.forEach { id in
            _updateFileFields.send(.init(
                id: id,
                newId: nil,
                fileNonce: nil,
                preview: nil,
                cached: nil,
                downloadStatus: downloadStatus,
                uploading: uploading,
                progress: progress
            ))
            
            if progress != nil {
                filesLoadingProgress[id] = progress
            }
        }
    }
    
    func sendProgress(for fileId: String, progress: Int) {
        guard filesLoadingProgress[fileId] != progress else { return }
        
        _updateFileFields.send(.init(
            id: fileId,
            newId: nil,
            fileNonce: nil,
            preview: nil,
            cached: nil,
            downloadStatus: nil,
            uploading: nil,
            progress: progress
        ))
        
        filesLoadingProgress[fileId] = progress
    }
}

// MARK: Upload
private extension ChatFileService {
    func sendFile(
        text: String?,
        chatroom: Chatroom?,
        fileMessage: FileMessage?,
        replyMessage: MessageModel?,
        saveEncrypted: Bool
    ) async throws {
        guard let partnerAddress = chatroom?.partner?.address,
              let keyPair = accountService.keypair,
              let ownerId = accountService.account?.address,
              var fileMessage = fileMessage,
              chatroom?.partner?.isDummy != true
        else { return }
        
        let storageProtocol = NetworkFileProtocolType.ipfs
        let files = fileMessage.files
        var richFiles = createRichFiles(from: files)
        
        let messageLocally = createAdamantMessage(
            with: richFiles,
            text: text,
            replyMessage: replyMessage,
            storageProtocol: storageProtocol
        )
        
        cachePreviewFiles(files)
        
        let txId = try await sendMessageLocallyIfNeeded(
            fileMessage: fileMessage,
            partnerAddress: partnerAddress,
            chatroom: chatroom,
            messageLocally: messageLocally
        )
        
        fileMessage.txId = txId
        
        let needToLoadFiles = richFiles.filter { $0.nonce.isEmpty }
        updateUploadingFilesIDs(with: needToLoadFiles.map { $0.id }, uploading: true)
        uploadingFilesDictionary[txId] = fileMessage

        do {
            try await processFilesUpload(
                fileMessage: &fileMessage,
                chatroom: chatroom,
                keyPair: keyPair,
                storageProtocol: storageProtocol,
                ownerId: ownerId,
                partnerAddress: partnerAddress,
                saveEncrypted: saveEncrypted, 
                txId: txId,
                richFiles: &richFiles,
                messageLocally: messageLocally
            )
            
            let message = createAdamantMessage(
                with: richFiles,
                text: text,
                replyMessage: replyMessage,
                storageProtocol: storageProtocol
            )
            
            _ = try await chatsProvider.sendFileMessage(
                message,
                recipientId: partnerAddress,
                transactionLocalyId: txId,
                from: chatroom
            )
            
            uploadingFilesDictionary[txId] = nil
        } catch {
            await handleUploadError(
                for: needToLoadFiles,
                txId: txId
            )
            
            throw error
        }
    }
    
    func createRichFiles(from files: [FileUpload]) -> [RichMessageFile.File] {
        files.compactMap {
            .init(
                id: $0.serverFileID ?? $0.file.url.absoluteString,
                size: $0.file.size,
                nonce: $0.fileNonce ?? .empty,
                name: $0.file.name,
                extension: $0.file.extenstion,
                mimeType: $0.file.mimeType,
                preview: $0.preview ?? $0.file.previewUrl.map {
                    RichMessageFile.Preview(
                        id: $0.absoluteString,
                        nonce: .empty,
                        extension: .empty
                    )
                },
                resolution: $0.file.resolution,
                duration: $0.file.duration
            )
        }
    }
    
    func createAdamantMessage(
        with richFiles: [RichMessageFile.File],
        text: String?,
        replyMessage: MessageModel?,
        storageProtocol: NetworkFileProtocolType
    ) -> AdamantMessage {
        guard let replyMessage = replyMessage else {
            return .richMessage(
                payload: RichMessageFile(
                    files: richFiles,
                    storage: .init(id: storageProtocol.rawValue),
                    comment: text
                )
            )
        }
        
        return .richMessage(
            payload: RichFileReply(
                replyto_id: replyMessage.id,
                reply_message: RichMessageFile(
                    files: richFiles,
                    storage: .init(id: storageProtocol.rawValue),
                    comment: text
                )
            )
        )
    }
    
    func cachePreviewFiles(_ files: [FileUpload]) {
        let needToCache = files.filter { !$0.isUploaded }
        for url in needToCache.compactMap({ $0.file.previewUrl }) {
            filesStorage.cacheTemporaryFile(
                url: url,
                isEncrypted: false,
                fileType: .image,
                isPreview: true
            )
        }
    }
    
    func sendMessageLocallyIfNeeded(
        fileMessage: FileMessage,
        partnerAddress: String,
        chatroom: Chatroom?,
        messageLocally: AdamantMessage
    ) async throws -> String {
        let txId: String
        
        if let transactionId = fileMessage.txId {
            txId = transactionId
            
            try? await chatsProvider.setTxMessageStatus(
                txId: txId,
                status: .pending
            )
        } else {
            let txLocallyId = try await chatsProvider.sendFileMessageLocally(
                messageLocally,
                recipientId: partnerAddress,
                from: chatroom
            )
            txId = txLocallyId
        }
        
        return txId
    }
    
    func updateUploadingFilesIDs(with ids: [String], uploading: Bool) {
        if uploading {
            uploadingFiles.append(contentsOf: ids)
        } else {
            ids.forEach { id in
                uploadingFiles.removeAll { $0 == id }
            }
        }
        
        sendUpdate(
            for: ids,
            downloadStatus: nil,
            uploading: uploading,
            progress: uploading ? .zero : nil
        )
    }
    
    func processFilesUpload(
        fileMessage: inout FileMessage,
        chatroom: Chatroom?,
        keyPair: Keypair,
        storageProtocol: NetworkFileProtocolType,
        ownerId: String,
        partnerAddress: String,
        saveEncrypted: Bool,
        txId: String,
        richFiles: inout [RichMessageFile.File],
        messageLocally: AdamantMessage
    ) async throws {
        let files = fileMessage.files
        
        for i in files.indices where !files[i].isUploaded {
            let file = files[i].file
            
            let uploadProgress: @Sendable (Int) -> Void = {
                // TODO: COMEBACK
                @MainActor [weak self, file] value in
                self?.sendProgress(
                    for: file.url.absoluteString,
                    progress: value
                )
            }
            
            let result = try await uploadFileToServer(
                file: file,
                recipientPublicKey: chatroom?.partner?.publicKey ?? .empty,
                senderPrivateKey: keyPair.privateKey,
                storageProtocol: storageProtocol, 
                progress: uploadProgress
            )
            
            sendProgress(
                for: result.file.cid,
                progress: 100
            )
            
            try cacheUploadedFile(
                fileResult: result.file,
                previewResult: result.preview,
                file: file,
                ownerId: ownerId,
                partnerAddress: partnerAddress,
                saveEncrypted: saveEncrypted
            )
            
            await updateRichFile(
                oldId: file.url.absoluteString,
                fileResult: result.file,
                previewResult: result.preview,
                fileMessage: &fileMessage,
                richFiles: &richFiles,
                file: file,
                txId: txId,
                messageLocally: messageLocally
            )
        }
    }
    
    func cacheUploadedFile(
        fileResult: UploadResult,
        previewResult: UploadResult?,
        file: FileResult,
        ownerId: String,
        partnerAddress: String,
        saveEncrypted: Bool
    ) throws {
        try filesStorage.cacheFile(
            id: fileResult.cid,
            fileExtension: file.extenstion ?? .empty,
            url: file.url,
            decodedData: fileResult.decodedData,
            encodedData: fileResult.encodedData,
            ownerId: ownerId,
            recipientId: partnerAddress,
            saveEncrypted: saveEncrypted,
            fileType: file.type,
            isPreview: false
        )
        
        if let previewUrl = file.previewUrl,
           let previewResult = previewResult {
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
        }
    }
    
    func updateRichFile(
        oldId: String,
        fileResult: UploadResult,
        previewResult: UploadResult?,
        fileMessage: inout FileMessage,
        richFiles: inout [RichMessageFile.File],
        file: FileResult,
        txId: String,
        messageLocally: AdamantMessage
    ) async {
        let cached = filesStorage.isCachedLocally(fileResult.cid)
        uploadingFiles.removeAll { $0 == oldId }
        
        _updateFileFields.send(.init(
            id: oldId,
            newId: fileResult.cid,
            fileNonce: fileResult.nonce,
            preview: .some(filesStorage.getPreview(for: previewResult?.cid ?? .empty)),
            cached: cached,
            downloadStatus: nil,
            uploading: false,
            progress: nil
        ))
        
        var previewDTO: RichMessageFile.Preview?
        if let cid = previewResult?.cid,
           let nonce = previewResult?.nonce {
            previewDTO = .init(
                id: cid,
                nonce: nonce,
                extension: file.previewExtension
            )
        }
        
        if let index = richFiles.firstIndex(where: { $0.id == oldId }) {
            richFiles[index].id = fileResult.cid
            richFiles[index].nonce = fileResult.nonce
            richFiles[index].preview = previewDTO
        }
        
        if let index = fileMessage.files.firstIndex(where: {
            $0.file.url.absoluteString == oldId
        }) {
            fileMessage.files[index].isUploaded = true
            fileMessage.files[index].serverFileID = fileResult.cid
            fileMessage.files[index].fileNonce = fileResult.nonce
            fileMessage.files[index].preview = previewDTO
            uploadingFilesDictionary[txId] = fileMessage
        }
        
        guard case let .richMessage(payload) = messageLocally,
              var richMessage = payload as? RichMessageFile
        else { return }
        
        richMessage.files = richFiles
        
        try? await chatsProvider.updateTxMessageContent(
            txId: txId,
            richMessage: richMessage
        )
    }
    
    func handleUploadError(
        for richFiles: [RichMessageFile.File],
        txId: String
    ) async {
        updateUploadingFilesIDs(with: richFiles.map { $0.id }, uploading: false)
        
        try? await chatsProvider.setTxMessageStatus(
            txId: txId,
            status: .failed
        )
    }
    
    func uploadFileToServer(
        file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String,
        storageProtocol: NetworkFileProtocolType,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> (file: UploadResult, preview: UploadResult?) {
        let totalProgress = Progress(totalUnitCount: 100)
        var previewWeight: Int64 = .zero
        var fileWeight: Int64 = 100
        
        if file.previewUrl != nil {
            previewWeight = 10
            fileWeight = 90
        }
        
        let previewProgress = Progress(totalUnitCount: previewWeight)
        totalProgress.addChild(previewProgress, withPendingUnitCount: previewWeight)
        
        let fileProgress = Progress(totalUnitCount: fileWeight)
        totalProgress.addChild(fileProgress, withPendingUnitCount: fileWeight)
        
        let result = try await uploadFile(
            url: file.url,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey,
            storageProtocol: storageProtocol,
            uploadProgress: { [fileWeight] value in
                fileProgress.completedUnitCount = Int64(value.fractionCompleted * Double(fileWeight))
                progress(Int(totalProgress.fractionCompleted * 100))
            }
        )
        
        var preview: UploadResult?
        
        if let url = file.previewUrl {
            preview = try await uploadFile(
                url: url,
                recipientPublicKey: recipientPublicKey,
                senderPrivateKey: senderPrivateKey,
                storageProtocol: storageProtocol,
                uploadProgress: { [previewWeight] value in
                    previewProgress.completedUnitCount = Int64(value.fractionCompleted * Double(previewWeight))
                    progress(Int(totalProgress.fractionCompleted * 100))
                }
            )
        }
        
        return (result, preview)
    }
    
    func uploadFile(
        url: URL,
        recipientPublicKey: String,
        senderPrivateKey: String,
        storageProtocol: NetworkFileProtocolType,
        uploadProgress: @escaping @Sendable (Progress) -> Void
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
        
        let cid = try await filesNetworkManager.uploadFiles(
            encodedData,
            type: storageProtocol,
            uploadProgress: uploadProgress
        ).get()
        
        return (data, encodedData, nonce, cid)
    }
}
