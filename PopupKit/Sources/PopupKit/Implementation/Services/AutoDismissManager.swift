//
//  File.swift
//  
//
//  Created by Andrey Golubenko on 07.12.2022.
//

import Combine
import Foundation

final class AutoDismissManager {
    private let popupCoordinatorModel: PopupCoordinatorModel
    
    private(set) var notificationDismissSubscription: AnyCancellable?
    private(set) var alertDismissSubscription: AnyCancellable?
    private(set) var toastDismissSubscription: AnyCancellable?
    
    init(popupCoordinatorModel: PopupCoordinatorModel) {
        self.popupCoordinatorModel = popupCoordinatorModel
    }
    
    func dismissNotification() {
        notificationDismissSubscription = setTimer { [weak self] in
            self?.notificationDismissSubscription = nil
            self?.popupCoordinatorModel.notification = nil
        }
    }
    
    func dismissAlert() {
        alertDismissSubscription = setTimer { [weak self] in
            self?.alertDismissSubscription = nil
            self?.popupCoordinatorModel.alert = nil
        }
    }
    
    func dismissToast() {
        toastDismissSubscription = setTimer { [weak self] in
            self?.toastDismissSubscription = nil
            self?.popupCoordinatorModel.toastMessage = nil
        }
    }
}

private extension AutoDismissManager {
    func setTimer(handler: @escaping () -> Void) -> AnyCancellable {
        Timer.publish(every: autoDismissTimeInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in handler() }
    }
}

private let autoDismissTimeInterval: TimeInterval = 4
