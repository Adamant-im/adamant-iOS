//
//  AdvancedContextMenuManager.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI
import UIKit

public protocol AdvancedContextMenuManagerDelegate: AnyObject {
    func getUpperContentView() -> AnyView?
    func configureUpperContentViewSize() -> CGSize
    func configureContextMenu() -> UIMenu
}

public extension AdvancedContextMenuManagerDelegate {
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
    private var overlayVCMac: UIHostingController<ContextMenuOverlayViewMac>?
    private var viewModel: ContextMenuOverlayViewModel?
    private var viewModelMac: ContextMenuOverlayViewModelMac?
    private weak var delegate: AdvancedContextMenuManagerDelegate?
    
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
    
    // MARK: Init
    
    public init(delegate: AdvancedContextMenuManagerDelegate) {
        self.delegate = delegate
    }
    
    // MARK: Public
    
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
        viewModelMac?.dismiss()
    }
}

// MARK: Private

private extension AdvancedContextMenuManager {
    @objc func handleLongPressMacOS(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let menu = delegate?.configureContextMenu()
        else { return }
        
        let location = gesture.location(in: nil)
        
        presentOverlayForMac(
            location: location,
            menu: menu
        )
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if isiOSAppOnMac {
            handleLongPressMacOS(gesture)
            return
        }
        
        guard gesture.state == .began,
              let contentView = gesture.view,
              let menu = delegate?.configureContextMenu()
        else { return }
            
        let locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
        
        let size = contentView.frame.size
        
        UIView.animate(withDuration: 0.29) {
            contentView.transform = .init(scaleX: 0.9, y: 0.9)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            self.contentView = contentView
            
            let previewView = contentView.snapshotView(afterScreenUpdates: true) ?? contentView

            self.presentOverlay(
                view: previewView,
                location: locationOnScreen,
                contentViewSize: size,
                menu: menu
            )

            UIView.animate(withDuration: 0.29) {
                contentView.alpha = 0
                contentView.transform = .identity
            }
        }
    }
    
    private func presentOverlay(
        view: UIView,
        location: CGPoint,
        contentViewSize: CGSize,
        menu: UIMenu
    ) {
        let upperView = self.delegate?.getUpperContentView()
        let upperViewSize = self.delegate?.configureUpperContentViewSize() ?? .zero
        
        let viewModel = ContextMenuOverlayViewModel(
            contentView: view,
            contentViewSize: contentViewSize,
            locationOnScreen: location,
            menu: menu,
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
        
        rootViewController()?.present(overlayVC, animated: false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func presentOverlayForMac(
        location: CGPoint,
        menu: UIMenu
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
        viewModelMac = viewModel
        
        rootViewController()?.present(overlayVC, animated: false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func rootViewController() -> UIViewController? {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        guard let windowScene = scene as? UIWindowScene else {
            return nil
        }
        
        return windowScene.keyWindow?.rootViewController
    }
}

// MARK: Delegate

extension AdvancedContextMenuManager: OverlayViewDelegate {
    func didDissmis() {
        contentView?.alpha = 1.0
        contentView = nil
        overlayVC?.dismiss(animated: false)
        overlayVCMac?.dismiss(animated: false)
    }
}
