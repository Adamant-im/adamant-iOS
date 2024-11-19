//
//  NotificationModel.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit
import CommonKit

struct NotificationModel: Equatable, Hashable {
    static func == (lhs: NotificationModel, rhs: NotificationModel) -> Bool {
        return lhs.icon == rhs.icon
        && lhs.title == rhs.title
        && lhs.description == rhs.description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(icon)
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(tapHandler)
    }
    
    let icon: UIImage?
    let title: String?
    let description: String?
    let tapHandler: IDWrapper<() -> Void>?
    let cancelAutoDismiss: () -> Void
}
