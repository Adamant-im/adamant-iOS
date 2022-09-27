//
//  TransferBaseProvider.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import UserNotifications
import MarkdownKit

class TransferBaseProvider: TransferNotificationContentProvider {
    
    /// Create notification content for Rich messages
    func notificationContent(for transaction: Transaction, partnerAddress: String, partnerName: String?, richContent: [String:String]) -> NotificationContent? {
        guard let amountRaw = richContent[RichContentKeys.transfer.amount], let amount = Decimal(string: amountRaw) else {
            return nil
        }
        
        let comment: String?
        if let raw = richContent[RichContentKeys.transfer.comments], raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        return notificationContent(partnerAddress: partnerAddress, partnerName: partnerName, amount: amount, comment: comment)
    }
    
    /// Create notification content for rich transfers with comments, such as ADM transfer
    func notificationContent(partnerAddress: String, partnerName: String?, amount: Decimal, comment: String?) -> NotificationContent? {
        let amountFormated = AdamantBalanceFormat.full.format(amount, withCurrencySymbol: currencySymbol)
        var body = String.adamantLocalized.notifications.yourTransferBody(with: amountFormated)
        
        if let comment = comment {
            let stripped = MarkdownParser().parse(comment).string
            body = "\(body)\n\(stripped)"
        }
        
        let identifier = type(of: self).richMessageType
        let attachments: [UNNotificationAttachment]?
        if let url = currencyLogoUrl,
            let attachment = try? UNNotificationAttachment(identifier: identifier, url: url) {
            attachments = [attachment]
        } else {
            attachments = nil
        }
        
        return NotificationContent(title: partnerName ?? partnerAddress,
                                   subtitle: String.adamantLocalized.notifications.newTransfer,
                                   body: body,
                                   attachments: attachments,
                                   categoryIdentifier: AdamantNotificationCategories.transfer)
    }
    
    // MARK: - To override
    
    class var richMessageType: String {
        fatalError("Provide richMessageType")
    }
    
    var currencyLogoLarge: UIImage {
        fatalError("Provide currency logo")
    }
    
    var currencyLogoUrl: URL? {
        fatalError("Provide currencyLogoUrl")
    }
    
    var currencySymbol: String {
        fatalError("Provide currencySymbol")
    }
    
    // MARK: - Private
    
    private func saveLocally(image: UIImage, name: String) -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(name).png")
        
        if fileManager.fileExists(atPath: url.path) {
            return url
        }
        
        guard let data = image.pngData() else {
            return nil
        }
        
        fileManager.createFile(atPath: url.path, contents: data, attributes: nil)
        return url
    }
}
