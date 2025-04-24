//
//  GestureHelper.swift
//  CommonKit
//
//  Created by Dmitrij Meidus on 23.04.25.
//

import UIKit

public protocol GestureHelper: NSObject {
    var GestureTaskManager: TaskManager { get set }
    var didPerformLongPressAction: Bool { get set }
}

public extension GestureHelper {
    func processLongPress(
        gesture: UILongPressGestureRecognizer,
        touchDuration: TimeInterval = 1.0,
        perform action: @escaping () -> Void,
        onGestureBegan onBegan: @escaping () -> Void,
        onGestureEnded onEnded: @escaping () -> Void
    ) {
        switch gesture.state {
            case .began:
                didPerformLongPressAction = false
                onBegan()
                
                Task { [weak self] in
                    try? await Task.sleep(interval: touchDuration)
                    let state = await gesture.state
                    guard let self = self,
                          state == .began || state == .changed
                    else { return }
                    await MainActor.run {
                        action()
                        onEnded()
                        self.didPerformLongPressAction = true
                    }
                }.stored(in: GestureTaskManager)
                
            case .ended:
                onEnded()
                GestureTaskManager.clean()
                
                if !didPerformLongPressAction {
                    action()
                }
                
            case .cancelled, .failed:
                onEnded()
                GestureTaskManager.clean()
                
            default:
                break
        }
    }
}
