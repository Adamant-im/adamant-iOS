//
//  FileMessageStatus.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import UIKit

enum FileMessageStatus: Hashable {
    case uploading
    case downloading
    case success
    case failed
    case needToDownload(failed: Bool)

    var image: UIImage {
        switch self {
        case .uploading:
            return UIImage(systemName: "square.fill") ?? UIImage()
        case .downloading:
            return .asset(named: "status_pending") ?? .init()
        case .success:
            return .asset(named: "status_success") ?? .init()
        case .failed:
            return .asset(named: "status_failed") ?? .init()
        case let .needToDownload(failed):
            guard !failed else {
                return .asset(named: "download-circular-error") ?? .init()
            }
            return .asset(named: "download-circular") ?? .init()
        }
    }

    var imageTintColor: UIColor {
        switch self {
        case .uploading, .downloading, .needToDownload, .success:
            return .adamant.primary
        case .failed:
            return .adamant.attention
        }
    }
}
