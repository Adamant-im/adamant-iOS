//
//  DownloadPolicy.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension Notification.Name {
     struct Storage {
         public static let storageClear = Notification.Name("adamant.storage.clear")
         public static let storageProprietiesUpdated = Notification.Name("adamant.storage.ProprietiesUpdated")
     }
 }

 enum DownloadPolicy: String {
     case everybody
     case nobody
     case contacts

     var title: String {
         switch self {
         case .everybody:
             return .localized("Storage.DownloadPolicy.Everybody.Title")
         case .nobody:
             return .localized("Storage.DownloadPolicy.Nobody.Title")
         case .contacts:
             return .localized("Storage.DownloadPolicy.Contacts.Title")
         }
     }
 }
