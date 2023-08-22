//
//  NotificationModel.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit
import CommonKit

struct NotificationModel: Equatable, Hashable {
    let icon: UIImage?
    let title: String?
    let description: String?
    let tapHandler: HashableAction?
}
