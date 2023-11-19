//
//  PopupCoordinatorModel.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit

final class PopupCoordinatorModel: ObservableObject {
    @Published var top: NotificationModel?
    @Published var middle: Alert?
    @Published var bottom: String?
    
    var notification: NotificationModel? {
        get { top }
        set { top = newValue }
    }
    
    var toastMessage: String? {
        get { bottom }
        set { bottom = newValue }
    }
    
    var alert: AlertModel? {
        get {
            switch middle {
            case let .common(model):
                return model
            case .none, .advanced:
                return nil
            }
        } set {
            switch middle {
            case .none, .common:
                middle = newValue.map { .common($0) }
            case .advanced:
                break
            }
        }
    }
    
    var advancedAlert: AdvancedAlertModel? {
        get {
            switch middle {
            case let .advanced(model):
                return model
            case .none, .common:
                return nil
            }
        } set {
            switch middle {
            case .none, .advanced:
                middle = newValue.map { .advanced($0) }
            case .common:
                break
            }
        }
    }
}

extension PopupCoordinatorModel {
    enum Alert {
        case common(AlertModel)
        case advanced(AdvancedAlertModel)
    }
}
