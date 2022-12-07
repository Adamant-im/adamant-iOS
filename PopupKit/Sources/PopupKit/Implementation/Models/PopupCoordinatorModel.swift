//
//  PopupCoordinatorModel.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit

final class PopupCoordinatorModel: ObservableObject {
    @Published var notification: NotificationModel?
    @Published var alert: AlertModel?
    @Published var toastMessage: String?
}
