//
//  Notification+Extension.swift
//  Adamant
//
//  Created by Andrew G on 07.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UserNotifications

extension NSAttributedString: @unchecked @retroactive Sendable {}
extension Notification: @unchecked @retroactive Sendable {}
extension UNNotificationResponse: @unchecked @retroactive Sendable {}
extension UNUserNotificationCenter: @unchecked @retroactive Sendable {}
