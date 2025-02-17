//
//  NotificationPresenterView.swift
//  PopupKit
//
//  Created by Yana Silosieva on 02.12.2024.
//

import SwiftUI
import CommonKit

struct NotificationPresenterView: View {
    enum DragDirection {
        case vertical
        case horizontal
    }
    @State private var isTextLimited: Bool = true
    @State private var dismissEdge: Edge = .top
    @State private var dragDirection: DragDirection?
    @State private var dynamicHeight: CGFloat = 0
    @State private var notificationHeight: CGFloat = 0
    @State private var offset: CGSize = .zero
    
    let model: NotificationModel
    let safeAreaInsets: EdgeInsets
    let dismissAction: () -> Void
    
    var body: some View {
        VStack {
            NotificationView(
                isTextLimited: $isTextLimited,
                model: model
            )
            .padding(10)
            .padding([.top, .bottom], 10)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            notificationHeight = geometry.size.height
                        }
                        .onChange(of: geometry.size.height) { newValue in
                            notificationHeight = newValue
                        }
                }
            )
        }
        .frame(minHeight: notificationHeight + dynamicHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.init(uiColor:.adamant.chatInputBarBorderColor), lineWidth: 1)
        )
        .background(GeometryReader(content: processGeometry))
        .onTapGesture(perform: onTap)
        .gesture(dragGesture)
        .cornerRadius(10)
        .padding(.horizontal, 15)
        .padding(.top, safeAreaInsets.top)
        .offset(offset)
        .animation(.interactiveSpring(), value: offset)
        .transition(.move(edge: dismissEdge))
    }
}
private extension NotificationPresenterView {
    func processGeometry(_ geometry: GeometryProxy) -> some View {
        return Color.init(uiColor: .adamant.swipeBlockColor)
            .cornerRadius(10)
    }
    func onTap() {
        model.tapHandler?.value()
        dismissAction()
        dismissEdge = .top
    }
}
private extension NotificationPresenterView {
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if dragDirection == nil || (abs(value.translation.width) <= 5 && abs(value.translation.height) <= 5) {
                    detectDragDirection(value: value)
                }
                if dragDirection == .vertical && isTextLimited {
                    dynamicHeight = max(0, min(value.translation.height, 30))
                }
                if dragDirection == .vertical, value.translation.height < 0 {
                    offset = CGSize(width: 0, height: value.translation.height)
                } else if dragDirection == .horizontal, value.translation.width < 0 {
                    offset = CGSize(width: value.translation.width, height: 0)
                }
            }
            .onEnded { value in
                if dragDirection == .vertical {
                    if value.translation.height > 25 {
                        model.cancelAutoDismiss?.value()
                        isTextLimited = false
                    } else if value.translation.height < -30 {
                        Task { dismissAction() }
                    }
                } else if dragDirection == .horizontal {
                    if value.translation.width < -100 {
                        dismissEdge = .leading
                        Task { dismissAction() }
                    }
                }
                dragDirection = nil
                dynamicHeight = 0
                offset = .zero
            }
    }
    
    func detectDragDirection(value: DragGesture.Value) {
        let horizontalDistance = abs(value.translation.width), verticalDistance = abs(value.translation.height)
        dragDirection = verticalDistance > horizontalDistance ? .vertical : .horizontal
    }
}
