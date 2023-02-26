import SwiftUI

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
        coordinatorModel.toastMessage = message
        autoDismissManager.dismissToast()
    }
    
    func dismissToast() {
        coordinatorModel.toastMessage = nil
    }
}

// MARK: - Alert

public extension PopupManager {
    func dismissAlert() {
        coordinatorModel.alert = nil
    }
    
    func showProgressAlert(message: String?, userInteractionEnabled: Bool) {
        autoDismissManager.alertDismissSubscription?.cancel()
        coordinatorModel.alert = .init(
            icon: .loading,
            message: message,
            userInteractionEnabled: userInteractionEnabled
        )
    }
    
    func showSuccessAlert(message: String?) {
        coordinatorModel.alert = .init(
            icon: .image(successImage),
            message: message,
            userInteractionEnabled: true
        )
        autoDismissManager.dismissAlert()
    }
    
    func showWarningAlert(message: String?) {
        coordinatorModel.alert = .init(
            icon: .image(warningImage),
            message: message,
            userInteractionEnabled: true
        )
        autoDismissManager.dismissAlert()
    }
}

// MARK: - Notification

public extension PopupManager {
    func showNotification(
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
            tapHandler: tapHandler.map { .init(id: .zero, action: $0) }
        )
        
        if autoDismiss {
            autoDismissManager.dismissNotification()
        } else {
            autoDismissManager.notificationDismissSubscription?.cancel()
        }
    }
    
    func dismissNotification() {
        coordinatorModel.notification = nil
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
