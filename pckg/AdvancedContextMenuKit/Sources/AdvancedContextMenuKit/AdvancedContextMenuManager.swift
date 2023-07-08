//
//  AdvancedContextMenuManager.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI
import UIKit

public protocol AdvancedContextMenuManagerDelegate: NSObject {
    func getPreviewView(for contentView: UIView) -> UIView?
    func getUpperContentView() -> AnyView?
    func configureUpperContentViewSize() -> CGSize
    func configureContextMenu() -> UIMenu
    func configureContextMenuAlignment() -> Alignment
}

public extension AdvancedContextMenuManagerDelegate {
    func getPreviewView(for contentView: UIView) -> UIView? {
        nil
    }
    
    func getUpperContentView() -> AnyView? {
        nil
    }
    
    func configureUpperContentViewSize() -> CGSize {
        .init(width: CGFloat.infinity, height: 50)
    }
}

public class AdvancedContextMenuManager: NSObject {
    private var contentView: UIView?
    private var overlayVC: UIHostingController<ContextMenuOverlayView>?
    private var viewModel: ContextMenuOverlayViewModel?
    private weak var delegate: AdvancedContextMenuManagerDelegate?
    
    public init(delegate: AdvancedContextMenuManagerDelegate) {
        self.delegate = delegate
    }

    public func setup(for contentView: UIView ) {
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.25
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    public func dismiss() {
        viewModel?.dismiss()
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let contentView = gesture.view,
              let menu = delegate?.configureContextMenu(),
              let menuAlignment = delegate?.configureContextMenuAlignment()
        else { return }
            
        let window = UIApplication.shared.keyWindow
        let locationInView: CGPoint = .zero //.init(x: contentView.frame.width / 2, y: contentView.frame.height / 2) //gesture.location(in: contentView)
        let locationOnScreen = contentView.convert(locationInView, to: window)

        let x = contentView.frame.origin.x
        let superViewXOffset = 8 + (contentView.superview?.frame.origin.x ?? .zero)
//        contentView.superview?.backgroundColor = .red.withAlphaComponent(0.4)

        UIView.animate(withDuration: 0.29) {
            contentView.transform = .init(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.contentView = contentView
           // contentView.transform = .identity
            
            let previewView = self.delegate?.getPreviewView(
                for: contentView
            ) ?? CommonPreviewView(contentView: contentView, x: x)
                        
            self.show(
                view: previewView,
                location: locationOnScreen,
                superViewXOffset: superViewXOffset,
                menu: menu,
                menuAlignment: menuAlignment
            ) { [weak self] in
                self?.contentView?.alpha = 0.0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.29) {
                    contentView.transform = .identity
                }
            }
        }
    }
    
    private func show(
        view: UIView,
        location: CGPoint,
        superViewXOffset: CGFloat,
        menu: UIMenu,
        menuAlignment: Alignment,
        completion: (() -> Void)?
    ) {
        let upperView = self.delegate?.getUpperContentView()
        let upperViewSize = self.delegate?.configureUpperContentViewSize() ?? .zero
        
        let viewModel = ContextMenuOverlayViewModel(
            contentView: view,
            topYOffset: location.y,
            newContentHeight: view.frame.height,
            oldContentHeight: contentView?.frame.height ?? view.frame.height,
            newContentWidth: contentView?.superview?.frame.width ?? view.frame.width,
            menu: menu,
            menuAlignment: menuAlignment,
            upperContentView: upperView,
            upperContentSize: upperViewSize,
            superViewXOffset: superViewXOffset
        )
        viewModel.delegate = self
        
        let overlay = ContextMenuOverlayView(
            viewModel: viewModel
        )
        
        let overlayVC = UIHostingController(rootView: overlay)
        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalPresentationCapturesStatusBarAppearance = true
        overlayVC.view.backgroundColor = .clear
        
        self.overlayVC = overlayVC
        self.viewModel = viewModel
        print("location.y=\(location.y)")
        
        UIApplication.shared.windows.first?.rootViewController?.present(overlayVC, animated: false) {
            completion?()
        }
    }
}

extension AdvancedContextMenuManager: OverlayViewDelegate {
    func didDissmis() {
        contentView?.alpha = 1.0
        contentView = nil
        overlayVC?.dismiss(animated: false)
    }
    
    func didDisplay() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
