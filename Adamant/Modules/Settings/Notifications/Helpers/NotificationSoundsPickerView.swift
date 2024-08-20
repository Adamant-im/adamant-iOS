//
//  NotificationSoundsPickerView.swift
//  Adamant
//
//  Created by Yana Silosieva on 17.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI

struct NotificationSoundsPickerView: UIViewControllerRepresentable {
    private let notificationService: NotificationsService
    private let notificationTarget: NotificationTarget
    
    init(notificationService: NotificationsService, target: NotificationTarget) {
        self.notificationService = notificationService
        self.notificationTarget = target
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = NotificationSoundsViewController(notificationsService: notificationService, target: notificationTarget)
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) { }
}
