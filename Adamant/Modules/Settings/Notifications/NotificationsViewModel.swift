//
//  NotificationsViewModel.swift
//  Adamant
//
//  Created by Yana Silosieva on 05.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit
import SafariServices
import MarkdownKit
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    
    @Published var notificationsMode: NotificationsMode = .disabled
    @Published var notificationSound: NotificationSound = .inputDefault
    @Published var notificationReactionSound: NotificationSound = .none
    @Published var githubRowImage: UIImage = .asset(named: "row_github") ?? UIImage()
    @Published var notificationsTitle: String = .localized("SecurityPage.Row.Notifications")
    @Published var presentSoundsPicker: Bool = false
    @Published var presentReactionSoundsPicker: Bool = false
    @Published var openSafariURL: Bool = false
    @Published var inAppSounds: Bool = false
    @Published var inAppVibrate: Bool = true
    @Published var inAppToasts: Bool = true
    
    var safariURL = URL(string: "https://github.com/Adamant-im")!
    
    private let dialogService: DialogService
    let notificationsService: NotificationsService
    private var subscriptions = Set<AnyCancellable>()
    
    nonisolated init(dialogService: DialogService, notificationsService: NotificationsService) {
        self.dialogService = dialogService
        self.notificationsService = notificationsService
        
        Task {
            await addObservers()
            await configure()
        }
    }
    
    func configure() {
        notificationsMode = notificationsService.notificationsMode
        notificationSound = notificationsService.notificationsSound
        notificationReactionSound = notificationsService.notificationsReactionSound
    }
    
    func presentNotificationSoundsPicker() {
        presentSoundsPicker = true
    }
    
    func presentReactionNotificationSoundsPicker() {
        presentReactionSoundsPicker = true
    }
    
    func presentSafariURL() {
        openSafariURL = true
    }
    
    func showAlert() {
        dialogService.showAlert(
            title: notificationsTitle,
            message: nil,
            style: .actionSheet,
            actions: [
                makeAction(
                    title: NotificationsMode.disabled.localized,
                    action: { [weak self] _ in
                        self?.setNotificationMode(.disabled)
                    }
                ),
                makeAction(
                    title: NotificationsMode.backgroundFetch.localized,
                    action: { [weak self] _ in
                        self?.setNotificationMode(.backgroundFetch)
                    }
                ),
                makeAction(
                    title: NotificationsMode.push.localized,
                    action: { [weak self] _ in
                        self?.setNotificationMode(.push)
                    }
                ),
                makeCancelAction()
            ],
            from: nil
        )
    }
    
    private func presentNotificationsDeniedError() {
        dialogService.showAlert(
            title: nil,
            message: NotificationStrings.notificationsDisabled,
            style: .alert,
            actions: [
                makeAction(
                    title: .adamant.alert.settings,
                    action: { _ in
                        self.openAppSettings()
                    }),
                makeAction(
                    title: String.adamant.alert.cancel,
                    action: nil
                )
            ],
            from: nil
        )
    }
    
    func setNotificationMode(_ mode: NotificationsMode) {
        guard mode != notificationsService.notificationsMode else {
            return
        }
        
        notificationsMode = mode
        notificationsService.setNotificationsMode(mode) { [weak self] result in
            DispatchQueue.onMainAsync {
                switch result {
                case .success:
                    return
                case .failure(let error):
                    switch error {
                    case .notEnoughMoney, .notStayedLoggedIn:
                        self?.dialogService.showRichError(error: error)
                    case .denied:
                        self?.presentNotificationsDeniedError()
                    }
                }
            }
        }
    }
    
    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
    
    func parseMarkdown(_ text: String) -> NSAttributedString? {
        let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize), color: UIColor.adamant.textColor)
        parser.link.color = UIColor.adamant.secondary
        return parser.parse(text)
    }
}

private extension NotificationsViewModel {
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantNotificationService.notificationsSoundChanged)
            .sink { [weak self] _ in self?.configure() }
            .store(in: &subscriptions)
    }
}

private extension NotificationsViewModel {
    func makeAction(title: String, action: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        .init(
            title: title,
            style: .default,
            handler: action
        )
    }
    
    func makeCancelAction() -> UIAlertAction {
        .init(title: .adamant.alert.cancel, style: .cancel, handler: nil)
    }
}
