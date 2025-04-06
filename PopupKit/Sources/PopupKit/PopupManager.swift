import CommonKit
import SwiftUI

@MainActor
public final class PopupManager {
    private let window = TransparentWindow(frame: UIScreen.main.bounds)
    private let coordinatorModel = PopupCoordinatorModel()

    private lazy var autoDismissManager = AutoDismissManager(
        popupCoordinatorModel: coordinatorModel
    )

    public func setup() {
        let rootView = PopupCoordinatorView(model: coordinatorModel)
        let rootVC = UIHostingController(rootView: rootView)
        rootVC.view.backgroundColor = .clear
        window.rootViewController = rootVC
        window.isHidden = false
    }

    public init() {}
}

// MARK: - Toast

public extension PopupManager {
    func showToastMessage(_ message: String) {
        autoDismissManager.dismissPreviousToast()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.coordinatorModel.toastMessage = message
            self?.autoDismissManager.dismissToast()
        }
        
        public func dismissToast() {
            coordinatorModel.toastMessage = nil
        }
    }

// MARK: - Alert

extension PopupManager {
    public func dismissAlert() {
        coordinatorModel.alert = nil
    }

    public func showProgressAlert(message: String?, userInteractionEnabled: Bool) {
        autoDismissManager.alertDismissSubscription?.cancel()
        coordinatorModel.alert = .init(
            icon: .loading,
            message: message,
            userInteractionEnabled: userInteractionEnabled
        )
    }

    public func showSuccessAlert(message: String?) {
        coordinatorModel.alert = .init(
            icon: .image(successImage),
            message: message,
            userInteractionEnabled: true
        )
        autoDismissManager.dismissAlert()
    }

    public func showWarningAlert(message: String?) {
        coordinatorModel.alert = .init(
            icon: .image(warningImage),
            message: message,
            userInteractionEnabled: true
        )
        autoDismissManager.dismissAlert()
    }
}

// MARK: - Notification

extension PopupManager {
    public func showNotification(
        icon: UIImage?,
        title: String?,
        description: String?,
        autoDismiss: Bool,
        tapHandler: (() -> Void)?
    ) {
        coordinatorModel.notification = .init(
            icon: icon,
            title: title,
            description: description,
            tapHandler: tapHandler.map { .init(id: .empty, value: $0) },
            cancelAutoDismiss: .init(
                id: .empty,
                value: { [weak self] in
                    self?.autoDismissManager.notificationDismissSubscription?.cancel()
                }
            )
        )

        if autoDismiss {
            autoDismissManager.dismissNotification()
        } else {
            autoDismissManager.notificationDismissSubscription?.cancel()
        }
    }

    public func dismissNotification() {
        coordinatorModel.notification = nil
    }
}

// MARK: - Advanced alert

extension PopupManager {
    public func dismissAdvancedAlert() {
        coordinatorModel.advancedAlert = nil
    }

    public func showAdvancedAlert(model: AdvancedAlertModel) {
        coordinatorModel.advancedAlert = model
    }
}

private let warningImage = UIImage(
    systemName: "multiply.circle",
    withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light)
)!

private let successImage = UIImage(
    systemName: "checkmark.circle",
    withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light)
)!
