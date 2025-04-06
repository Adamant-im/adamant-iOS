//
//  NotificationModel.swift
//
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import CommonKit
import UIKit

struct NotificationModel: Equatable, Hashable {
    let icon: UIImage?
    let title: String?
    let description: String?
    let tapHandler: IDWrapper<() -> Void>?
    let cancelAutoDismiss: IDWrapper<() -> Void>?
}
