//
//  ChatFileProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 22.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import Combine
import UIKit
import FilesStorageKit

struct FileUpdateProperties {
    let id: String
    let newId: String?
    let fileNonce: String?
    let preview: UIImage??
    let cached: Bool?
    let downloadStatus: DownloadStatus?
    let uploading: Bool?
    let progress: Int?
}

@MainActor
protocol ChatFileProtocol: Sendable {
    var downloadingFiles: [String: DownloadStatus] { get }
    var uploadingFiles: [String] { get }
    var filesLoadingProgress: [String: Int] { get }
    var updateFileFields: AnyObservable<FileUpdateProperties> { get }
    
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
        saveEncrypted: Bool,
        previewDownloadAllowed: Bool,
        fullMediaDownloadAllowed: Bool
    ) async throws
    
    func autoDownload(
        file: ChatFile,
        chatroom: Chatroom?,
        hasPartnerName: Bool,
        previewDownloadPolicy: DownloadPolicy,
        fullMediaDownloadPolicy: DownloadPolicy,
        saveEncrypted: Bool
    ) async
    
    func getDecodedData(
        file: FilesStorageKit.File,
        nonce: String,
        chatroom: Chatroom?
    ) throws -> Data
    
    func resendMessage(
        with id: String,
        text: String?,
        chatroom: Chatroom?,
        replyMessage: MessageModel?,
        saveEncrypted: Bool
    ) async throws
    
    func isDownloadPreviewLimitReached(for fileId: String) -> Bool
    
    func isPreviewAutoDownloadAllowedByPolicy(
        hasPartnerName: Bool,
        isFromCurrentSender: Bool,
        downloadPolicy: DownloadPolicy
    ) -> Bool
    
    func isOriginalAutoDownloadAllowedByPolicy(
        hasPartnerName: Bool,
        isFromCurrentSender: Bool,
        downloadPolicy: DownloadPolicy
    ) -> Bool
}
