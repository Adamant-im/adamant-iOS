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
    private let calendar: Calendar
    
    private(set) var notificationDismissTask: Cancellable?
    private(set) var alertDismissTask: Cancellable?
    private(set) var toastDismissTask: Cancellable?
    
    init(popupCoordinatorModel: PopupCoordinatorModel, calendar: Calendar) {
        self.popupCoordinatorModel = popupCoordinatorModel
        self.calendar = calendar
    }
    
    func dismissNotification() {
        notificationDismissTask?.cancel()
        notificationDismissTask = OperationQueue.main.schedule(
            after: .init(makeDismissDate()),
            interval: .zero
        ) { [weak popupCoordinatorModel] in
            popupCoordinatorModel?.notification = nil
        }
    }
    
    func dismissAlert() {
        alertDismissTask?.cancel()
        alertDismissTask = OperationQueue.main.schedule(
            after: .init(makeDismissDate()),
            interval: .zero
        ) { [weak popupCoordinatorModel] in
            popupCoordinatorModel?.alert = nil
        }
    }
    
    func dismissToast() {
        toastDismissTask?.cancel()
        toastDismissTask = OperationQueue.main.schedule(
            after: .init(makeDismissDate()),
            interval: .zero
        ) { [weak popupCoordinatorModel] in
            popupCoordinatorModel?.toastMessage = nil
        }
    }
}

private extension AutoDismissManager {
    func makeDismissDate() -> Date {
        guard let date = calendar.date(byAdding: .second, value: autoDismissTimeInterval, to: Date()) else {
            assertionFailure("Date is nil")
            return Date()
        }
        
        return date
    }
}

private let autoDismissTimeInterval: Int = 4
