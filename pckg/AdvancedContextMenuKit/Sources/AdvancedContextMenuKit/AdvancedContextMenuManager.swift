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
    func configureContextMenu() -> AMenuSection
}

public extension AdvancedContextMenuManagerDelegate {
    func getUpperContentView() -> AnyView? {
        nil
    }
    
    func configureUpperContentViewSize() -> CGSize {
        .init(width: CGFloat.infinity, height: 50)
    }
}

public final class AdvancedContextMenuManager: NSObject {
    private var superView: UIView?
    private var contentView: UIView?
    private var contentViewIndex: Int = 0
    private var contentViewFrame: CGRect?
    private var overlayVC: UIHostingController<ContextMenuOverlayView>?
    private var overlayVCMac: UIHostingController<ContextMenuOverlayViewMac>?
    private var viewModel: ContextMenuOverlayViewModel?
    private var viewModelMac: ContextMenuOverlayViewModelMac?
    private weak var delegate: AdvancedContextMenuManagerDelegate?
    private let maxContentHeight: CGFloat = 500
    
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
    
    public func presentMenu(for contentView: UIView, with menu: AMenuSection) {
        let locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
                
        self.contentView = contentView
        
        guard !isiOSAppOnMac else {
            presentOverlayForMac(
                location: locationOnScreen,
                menu: menu
            )
            return
        }
        
        contentView.isUserInteractionEnabled = false
        
        self.contentViewFrame = contentView.frame
        self.superView = contentView.superview

        if let superView = superView as? UIStackView {
            contentViewIndex = superView.arrangedSubviews.firstIndex(of: contentView) ?? 0
        } else {
            contentViewIndex = superView?.subviews.firstIndex(of: contentView) ?? 0
        }
        
        let menuVC = getMenuVC(content: menu)
        
        self.presentOverlay(
            view: contentView,
            location: locationOnScreen,
            contentViewSize: contentView.frame.size,
            menu: menuVC
        )
    }
    
    public func dismiss(completion: (() -> Void)? = nil) {
        viewModel?.dismiss()
        viewModelMac?.dismiss()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion?()
        }
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
        guard !isiOSAppOnMac else {
            handleLongPressMacOS(gesture)
            return
        }
        
        guard gesture.state == .began,
              let contentView = gesture.view,
              let menu = delegate?.configureContextMenu()
        else { return }
            
        let locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
        
        let size = contentView.frame.size
        self.contentViewFrame = contentView.frame
        self.contentView = contentView
        self.superView = contentView.superview

        if let superView = superView as? UIStackView {
            contentViewIndex = superView.arrangedSubviews.firstIndex(of: contentView) ?? 0
        } else {
            contentViewIndex = superView?.subviews.firstIndex(of: contentView) ?? 0
        }
        
        let scale: CGFloat = contentView.bounds.height > maxContentHeight
        ? 0.99
        : 0.9
        
        contentView.isUserInteractionEnabled = false
        
        let menuVC = getMenuVC(content: menu)
        
        UIView.animate(withDuration: 0.29) {
            contentView.transform = .init(scaleX: scale, y: scale)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            self.presentOverlay(
                view: contentView,
                location: locationOnScreen,
                contentViewSize: size,
                menu: menuVC
            )

            UIView.animate(withDuration: 0.35) {
                contentView.transform = .identity
            }
        }
    }
    
    private func presentOverlay(
        view: UIView,
        location: CGPoint,
        contentViewSize: CGSize,
        menu: AMenuViewController?
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
        menu: AMenuSection
    ) {
        let upperView = self.delegate?.getUpperContentView()
        let upperViewSize = self.delegate?.configureUpperContentViewSize() ?? .zero
        
        let menuVC = getMenuVC(content: menu)
        
        let viewModel = ContextMenuOverlayViewModelMac(
            menu: menuVC,
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
    
    func getMenuVC(content: AMenuSection) -> AMenuViewController {
        let menuViewController = AMenuViewController(menuContent: content)
        
        menuViewController.finished = { [weak self] action in
            self?.dismiss {
                action?()
            }
        }
        
        return menuViewController
    }
}

// MARK: Delegate

extension AdvancedContextMenuManager: OverlayViewDelegate {
    func didDissmis() {
        if let contentView = contentView,
           let contentViewFrame = contentViewFrame {
            if let superView = superView as? UIStackView {
                superView.insertArrangedSubview(contentView, at: contentViewIndex)
            } else {
                superView?.insertSubview(contentView, at: contentViewIndex)
            }
            contentView.frame = contentViewFrame
        }
        contentView?.isUserInteractionEnabled = true
        contentView?.alpha = 1.0
        overlayVC?.dismiss(animated: false)
        overlayVCMac?.dismiss(animated: false)
    }
}
