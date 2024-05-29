//
//  FileMessageStatus.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit

enum FileMessageStatus {
    case busy
    case needToDownload
    case failed
    case success
    
    var image: UIImage {
        switch self {
        case .busy: return .asset(named: "status_pending") ?? .init()
        case .success: return .asset(named: "status_success") ?? .init()
        case .failed: return .asset(named: "status_failed") ?? .init()
        case .needToDownload: return .asset(named: "download-circular") ?? .init()
        }
    }
    
    var imageTintColor: UIColor {
        switch self {
        case .busy, .needToDownload, .success: return .adamant.primary
        case .failed: return .adamant.alert
        }
    }
}
