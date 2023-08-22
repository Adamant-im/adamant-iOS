//
//  AdvancedContextMenuManager.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI
import UIKit
import CommonKit

public protocol AdvancedContextMenuManagerDelegate: AnyObject {
    func getUpperContentView() -> AnyView?
    func getContentView() -> UIView?
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

@MainActor
public final class AdvancedContextMenuManager: NSObject {
    private var contentView: UIView?
    private var viewModel: ContextMenuOverlayViewModel?
    private var viewModelMac: ContextMenuOverlayViewModelMac?
    private weak var delegate: AdvancedContextMenuManagerDelegate?
    private let maxContentHeight: CGFloat = 500
    private let window = TransparentWindow(frame: UIScreen.main.bounds)
    private var locationOnScreen: CGPoint = .zero

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
        guard !isiOSAppOnMac else {
            let interaction = UIContextMenuInteraction(delegate: self)
            contentView.addInteraction(interaction)
            return
        }
        
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.17
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    public func presentMenu(
        for contentView: UIView,
        copyView: UIView?,
        with menu: AMenuSection
    ) {
        locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
                
        self.contentView = contentView
        
        let copyView = copyView ?? contentView.snapshotView(afterScreenUpdates: true)
        guard let copyView = copyView else { return }
        
        let containerCopyView = ContanierPreviewView(
            contentView: copyView,
            scale: 1.0,
            size: contentView.frame.size,
            animationInDuration: animationOutDuration
        )
        
        guard !isiOSAppOnMac else {
            presentOverlayForMac(
                contentView: containerCopyView,
                contentViewSize: contentView.frame.size,
                location: locationOnScreen,
                contentLocation: locationOnScreen,
                menu: menu
            )
            return
        }
        
        let menuVC = getMenuVC(content: menu)
        
        contentView.alpha = .zero
        
        self.presentOverlay(
            view: containerCopyView,
            location: locationOnScreen,
            contentViewSize: contentView.frame.size,
            menu: menuVC
        )
    }
    
    @MainActor
    public func dismiss() async {
        await viewModel?.dismiss()
        await viewModelMac?.dismiss()
    }
}

// MARK: Private

private extension AdvancedContextMenuManager {
    func presentMacOverlay(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) {
        guard let contentView = interaction.view,
              let menu = delegate?.configureContextMenu()
        else { return }
        
        let contentLocation = contentView.convert(CGPoint.zero, to: nil)
        let location: CGPoint = .init(
            x: contentLocation.x + location.x,
            y: contentLocation.y + location.y
        )
        let size = contentView.frame.size
        
        let copyView = delegate?.getContentView() ?? contentView.snapshotView(afterScreenUpdates: true)
        
        guard let copyView = copyView else { return }
        
        self.contentView = contentView
        
        presentOverlayForMac(
            contentView: copyView,
            contentViewSize: size,
            location: location,
            contentLocation: contentLocation,
            menu: menu
        )
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard !isiOSAppOnMac else { return }
        
        guard gesture.state == .began,
              let contentView = gesture.view,
              let menu = delegate?.configureContextMenu()
        else { return }
            
        locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
        
        self.contentView = contentView
        
        let menuVC = getMenuVC(content: menu)
        let size = contentView.frame.size
        let scale: CGFloat = contentView.bounds.height > maxContentHeight
        ? 0.99
        : 0.9
        
        let copyView = delegate?.getContentView() ?? contentView.snapshotView(afterScreenUpdates: true)
        
        guard let copyView = copyView else { return }
        
        let containerCopyView = ContanierPreviewView(
            contentView: copyView,
            scale: scale,
            size: size,
            animationInDuration: animationOutDuration
        )
        
        UIView.animate(withDuration: animationInDuration) {
            contentView.transform = .init(scaleX: scale, y: scale)
        } completion: { [weak self] _ in
            guard let self = self else { return }
            contentView.alpha = .zero
            
            self.presentOverlay(
                view: containerCopyView,
                location: locationOnScreen,
                contentViewSize: size,
                menu: menuVC
            )
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
            upperContentSize: upperViewSize,
            animationDuration: animationOutDuration
        )
        viewModel.delegate = self
        
        let overlay = ContextMenuOverlayView(
            viewModel: viewModel
        )
        
        let overlayVC = UIHostingController(rootView: overlay)
        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalPresentationCapturesStatusBarAppearance = true
        overlayVC.view.backgroundColor = .clear
        
        self.viewModel = viewModel
        
        present(vc: overlayVC)
    }
    
    private func presentOverlayForMac(
        contentView: UIView,
        contentViewSize: CGSize,
        location: CGPoint,
        contentLocation: CGPoint,
        menu: AMenuSection
    ) {
        let upperView = self.delegate?.getUpperContentView()
        let upperViewSize = self.delegate?.configureUpperContentViewSize() ?? .zero
        
        let menuVC = getMenuVC(content: menu)
        
        let viewModel = ContextMenuOverlayViewModelMac(
            contentView: contentView,
            contentViewSize: contentViewSize,
            menu: menuVC,
            upperContentView: upperView,
            upperContentSize: upperViewSize,
            locationOnScreen: location,
            contentLocation: contentLocation,
            animationDuration: animationOutDuration,
            delegate: self
        )
        
        let overlay = ContextMenuOverlayViewMac(
            viewModel: viewModel
        )
        
        let overlayVC = UIHostingController(rootView: overlay)
        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalPresentationCapturesStatusBarAppearance = true
        overlayVC.view.backgroundColor = .clear
        
        viewModelMac = viewModel
        
        present(vc: overlayVC)
    }
    
    func present(vc: UIViewController) {
        window.rootViewController = vc
        window.makeKeyAndVisible()
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func getMenuVC(content: AMenuSection) -> AMenuViewController {
        let menuViewController = AMenuViewController(menuContent: content)
        
        menuViewController.finished = { [weak self] action in
            guard let self = self else { return }
            Task {
                await self.dismiss()
                action?()
            }
        }
        
        return menuViewController
    }
}

// MARK: Delegate

extension AdvancedContextMenuManager: OverlayViewDelegate {
    @MainActor func didDissmis() {
        contentView?.alpha = 1.0
        // Postpone window dismissal to the next iteration to allow the contentView to become visible
        Task {
            window.rootViewController = nil
            window.isHidden = true
        }
    }
    
    @MainActor func didAppear() {
        contentView?.transform = .identity
        let newLocationOnScreen = contentView?.convert(CGPoint.zero, to: nil) ?? locationOnScreen
        guard newLocationOnScreen != locationOnScreen else { return }
        
        locationOnScreen = newLocationOnScreen
        viewModel?.update(locationOnScreen: newLocationOnScreen)
    }
}

extension AdvancedContextMenuManager: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        presentMacOverlay(interaction, configurationForMenuAtLocation: location)
        return nil
    }
}

private let animationInDuration: TimeInterval = 0.25
private let animationOutDuration: TimeInterval = 0.18
