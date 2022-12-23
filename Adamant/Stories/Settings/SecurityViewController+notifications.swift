//
//  SecurityViewController+notifications.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

extension SecurityViewController {
    func setNotificationMode(_ mode: NotificationsMode) {
        guard mode != notificationsService.notificationsMode else {
            return
        }
        
        notificationsService.setNotificationsMode(mode) { [weak self] result in
            switch result {
            case .success:
                return
                
            case .failure(let error):
                if let row: SwitchRow = self?.form.rowBy(tag: Rows.notificationsMode.tag) {
                    row.value = false
                    row.updateCell()
                }
                
                switch error {
                case .notEnoughMoney, .notStayedLoggedIn:
                    self?.dialogService.showRichError(error: error)
                    
                case .denied:
                    DispatchQueue.main.async {
                        self?.presentNotificationsDeniedError()
                    }
                }
            }
        }
    }
    
    private func presentNotificationsDeniedError() {
        let alert = UIAlertController(title: nil, message: String.adamantLocalized.notifications.notificationsDisabled, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
            DispatchQueue.main.async {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
}
