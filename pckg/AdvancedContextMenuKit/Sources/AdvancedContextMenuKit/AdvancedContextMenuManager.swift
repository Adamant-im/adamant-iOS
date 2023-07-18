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
    private var overlayVCMac: UIHostingController<ContextMenuOverlayViewMac>?
    
    var isiOSAppOnMac: Bool = {
#if targetEnvironment(macCatalyst)
        return true
#else
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        } else {
            return false
        }
#endif
    }()
    
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
    
    @objc func handleLongPressMacOS(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let menu = delegate?.configureContextMenu()
        else { return }
        
        let location = gesture.location(in: nil)
        
        presentOverlayForMac(
            location: location,
            menu: menu,
            completion: nil
        )
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
//        if isiOSAppOnMac {
//            handleLongPressMacOS(gesture)
//            return
//        }
        
        guard gesture.state == .began,
              let contentView = gesture.view,
              let menu = delegate?.configureContextMenu(),
              let menuAlignment = delegate?.configureContextMenuAlignment()
        else { return }
            
        let window = UIApplication.shared.keyWindow
        let locationOnScreen = contentView.convert(CGPoint.zero, to: window)
        
        let size = contentView.frame.size
        
        UIView.animate(withDuration: 0.29) {
            contentView.transform = .init(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.contentView = contentView
            
            let previewView = contentView.snapshotView(afterScreenUpdates: true) ?? contentView

            self.show(
                view: previewView,
                location: locationOnScreen,
                contentViewSize: size,
                menu: menu,
                menuAlignment: menuAlignment
            )

            UIView.animate(withDuration: 0.29) {
                contentView.alpha = 0
                contentView.transform = .identity
            }
        }
    }
    
    private func show(
        view: UIView,
        location: CGPoint,
        contentViewSize: CGSize,
        menu: UIMenu,
        menuAlignment: Alignment,
        completion: (() -> Void)? = nil
    ) {
        let upperView = self.delegate?.getUpperContentView()
        let upperViewSize = self.delegate?.configureUpperContentViewSize() ?? .zero
        
        let viewModel = ContextMenuOverlayViewModel(
            contentView: view,
            contentViewSize: contentViewSize,
            locationOnScreen: location,
            menu: menu,
            menuAlignment: menuAlignment,
            upperContentView: upperView,
            upperContentSize: upperViewSize
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
        
        UIApplication.shared.windows.first?.rootViewController?.present(overlayVC, animated: false) {
            completion?()
        }
    }
    
    private func presentOverlayForMac(
        location: CGPoint,
        menu: UIMenu,
        completion: (() -> Void)?
    ) {
        let upperView = self.delegate?.getUpperContentView()
        let upperViewSize = self.delegate?.configureUpperContentViewSize() ?? .zero
        
        let viewModel = ContextMenuOverlayViewModelMac(
            menu: menu,
            upperContentView: upperView,
            upperContentSize: upperViewSize,
            locationOnScreen: location,
            delegate: self
        )
        
        let overlay = ContextMenuOverlayViewMac(
            viewModel: viewModel
        )
        
        let overlayVC = UIHostingController(rootView: overlay)
        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalPresentationCapturesStatusBarAppearance = true
        overlayVC.view.backgroundColor = .clear
        
        overlayVCMac = overlayVC
        
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
        overlayVCMac?.dismiss(animated: false)
    }
    
    func didDisplay() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
