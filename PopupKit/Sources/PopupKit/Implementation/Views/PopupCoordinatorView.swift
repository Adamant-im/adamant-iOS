//
//  PopupCoordinatorView.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI

struct PopupCoordinatorView: View {
    @ObservedObject var model: PopupCoordinatorModel
    
    var body: some View {
        GeometryReader { geomerty in
            ZStack {
                if !(model.alert?.userInteractionEnabled ?? true) {
                    BlockingView()
                }
                
                makeNotificationView(safeAreaInsets: geomerty.safeAreaInsets)
                makeAlertView()
                makeToastView(safeAreaInsets: geomerty.safeAreaInsets)
            }
            .expanded()
            .ignoresSafeArea()
        }
    }
}

private extension PopupCoordinatorView {
    func makeNotificationView(safeAreaInsets: EdgeInsets) -> some View {
        VStack {
            if let notificationModel = model.notification {
                NotificationView(
                    model: notificationModel,
                    safeAreaInsets: safeAreaInsets,
                    dismissAction: { [weak model] in
                        model?.notification = nil
                    }
                )
                .id(model.notification?.hashValue)
                .transition(.move(edge: .top))
            }
            Spacer()
        }
        .animation(.easeInOut(duration: animationDuration), value: model.notification?.hashValue)
    }
    
    func makeAlertView() -> some View {
        VStack {
            if let alertModel = model.alert {
                AlertView(model: alertModel)
                    .id(model.alert?.hashValue)
                    .transition(.scale)
            }
        }
        .animation(.easeInOut(duration: animationDuration), value: model.alert?.hashValue)
    }
    
    func makeToastView(safeAreaInsets: EdgeInsets) -> some View {
        VStack {
            Spacer()
            if let message = model.toastMessage {
                ToastView(message: message)
                    .padding(.bottom, safeAreaInsets.bottom)
                    .id(model.toastMessage?.hashValue)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: animationDuration), value: model.toastMessage?.hashValue)
    }
}

private let animationDuration: TimeInterval = 0.2