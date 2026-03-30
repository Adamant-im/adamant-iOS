//
//  AdvancedContextMenuManager.swift
//
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import CommonKit
import SwiftUI
import UIKit

@MainActor
public final class AdvancedContextMenuManager: NSObject {
    private var viewModel: ContextMenuOverlayViewModel?
    private var viewModelMac: ContextMenuOverlayViewModelMac?
    private var vcOverlay: UIViewController?
    private var window: TransparentWindow?
    private weak var sourceView: UIView?
    private var locationOnScreen: CGPoint = .zero
    private var getPositionOnScreen: (() -> CGPoint)?
    private var messageId: String = ""

    public var didAppearMenuAction: ((_ messageId: String) -> Void)?
    public var didPresentMenuAction: ((_ messageId: String) -> Void)?
    public var didDismissMenuAction: ((_ messageId: String) -> Void)?

    // MARK: Public

    public func presentMenu(
        arg: ChatContextMenuArguments,
        upperView: AnyView?,
        upperViewSize: CGSize
    ) {
        self.messageId = arg.messageId
        self.locationOnScreen = arg.location
        self.getPositionOnScreen = arg.getPositionOnScreen
        self.sourceView = arg.copyView

        let containerCopyView = ContanierPreviewView(
            contentView: arg.copyView,
            scale: 1.0,
            size: arg.size,
            animationInDuration: animationOutDuration
        )

        guard !isMacOS else {
            presentOverlayForMac(
                contentView: containerCopyView,
                contentViewSize: arg.size,
                location: arg.tapLocation,
                contentLocation: arg.location,
                menu: arg.menu,
                upperView: upperView,
                upperViewSize: upperViewSize
            )
            return
        }

        let menuVC = getMenuVC(content: arg.menu)

        self.presentOverlay(
            view: containerCopyView,
            location: arg.location,
            contentViewSize: arg.size,
            menu: menuVC,
            upperView: upperView,
            upperViewSize: upperViewSize
        )
    }

    @MainActor
    public func dismiss() async {
        await viewModel?.dismiss()
        await viewModelMac?.dismiss()
    }

    @MainActor
    public func presentOver(_ vc: UIViewController, animated: Bool) {
        vcOverlay?.present(vc, animated: animated)
    }
}

// MARK: Private

extension AdvancedContextMenuManager {
    private func presentOverlay(
        view: UIView,
        location: CGPoint,
        contentViewSize: CGSize,
        menu: AMenuViewController?,
        upperView: AnyView?,
        upperViewSize: CGSize
    ) {
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

        let overlayVC = OverlayHostingController(
            rootView: overlay,
            dismissAction: { [weak self] in self?.dismissSync() }
        )

        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalPresentationCapturesStatusBarAppearance = true
        overlayVC.view.backgroundColor = .clear

        self.viewModel = viewModel

        present(vc: overlayVC)
    }

    fileprivate func presentOverlayForMac(
        contentView: UIView,
        contentViewSize: CGSize,
        location: CGPoint,
        contentLocation: CGPoint,
        menu: AMenuSection,
        upperView: AnyView?,
        upperViewSize: CGSize
    ) {
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

        let overlayVC = OverlayHostingController(
            rootView: overlay,
            dismissAction: { [weak self] in self?.dismissSync() }
        )

        overlayVC.modalPresentationStyle = .overFullScreen
        overlayVC.modalPresentationCapturesStatusBarAppearance = true
        overlayVC.view.backgroundColor = .clear

        viewModelMac = viewModel

        present(vc: overlayVC)
    }

    fileprivate func present(vc: UIViewController) {
        let window = getWindow(for: sourceView)
        window.rootViewController = vc
        window.makeKeyAndVisible()

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        didPresentMenuAction?(messageId)
        vcOverlay = vc
    }

    fileprivate func getWindow(for sourceView: UIView?) -> TransparentWindow {
        let scene = sourceView?.window?.windowScene ?? getActiveWindowScene()

        if let scene {
            if let window, window.windowScene === scene {
                configure(window: window, scene: scene)
                return window
            }

            tearDownWindow()
            let window = TransparentWindow(windowScene: scene)
            configure(window: window, scene: scene)
            self.window = window
            return window
        }

        if let window {
            configure(window: window, frame: UIScreen.main.bounds)
            return window
        }

        let window = TransparentWindow(frame: UIScreen.main.bounds)
        configure(window: window, frame: UIScreen.main.bounds)
        self.window = window
        return window
    }

    fileprivate func getActiveWindowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        return scenes.first {
            $0.activationState == .foregroundActive
                && $0.windows.contains(where: \.isKeyWindow)
        }
        ?? scenes.first(where: { $0.activationState == .foregroundActive })
        ?? scenes.first(where: { $0.windows.contains(where: \.isKeyWindow) })
        ?? scenes.first
    }

    fileprivate func configure(window: TransparentWindow, scene: UIWindowScene) {
        configure(window: window, frame: scene.coordinateSpace.bounds)
    }

    fileprivate func configure(window: TransparentWindow, frame: CGRect) {
        window.frame = frame
        window.backgroundColor = .clear
    }

    fileprivate func tearDownWindow() {
        window?.rootViewController = nil
        window?.isHidden = true
        window = nil
    }

    fileprivate func getMenuVC(content: AMenuSection) -> AMenuViewController {
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

    fileprivate func dismissSync() {
        Task { await dismiss() }
    }
}

// MARK: Delegate

extension AdvancedContextMenuManager: OverlayViewDelegate {
    func willDissmis() {
        guard
            let newPosition = getPositionOnScreen?(),
            newPosition != locationOnScreen
        else { return }

        viewModel?.update(locationOnScreen: newPosition)
    }

    func didDissmis() {
        didDismissMenuAction?(messageId)
        getPositionOnScreen = nil
        sourceView = nil
        vcOverlay = nil
        // Postpone window dismissal to the next iteration to allow the contentView to become visible
        Task {
            // TODO: Bug - Occasionally, the copied content view disappears faster than the original view is presented. Fix it later.
            try await Task.sleep(interval: 0.1)
            tearDownWindow()
        }
    }

    func didAppear() {
        if let newPosition = getPositionOnScreen?(),
            newPosition != locationOnScreen
        {
            viewModel?.update(locationOnScreen: newPosition)
        }

        didAppearMenuAction?(messageId)
    }
}

private let animationInDuration: TimeInterval = 0.25
private let animationOutDuration: TimeInterval = 0.18
