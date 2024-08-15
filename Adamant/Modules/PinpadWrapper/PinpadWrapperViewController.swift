//
//  PinpadWrapperViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import Combine
import MyLittlePinpad

final class PinpadWrapperViewController: UIViewController {
    private let viewModel: PinpadWrapperViewModel
    private var subscriptions = Set<AnyCancellable>()
    
    var successAction: (() -> Void)?

    init(viewModel: PinpadWrapperViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError(.empty)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPinpad()
        setupObservers()
    }
}

private extension PinpadWrapperViewController {
    func setupObservers() {
        viewModel.successAction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.successAction?() }
            .store(in: &subscriptions)
        
        viewModel.pinpadEnable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.pinpadEnable($0) }
            .store(in: &subscriptions)

    }
    
    func setupPinpad() {
        let pinpad = viewModel.pinpad
        addChild(pinpad)
        view.addSubview(pinpad.view)
        pinpad.view.frame = view.bounds
        pinpad.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pinpad.didMove(toParent: self)
        
        pinpad.commentLabel.text = .adamant.login.loginIntoPrevAccount
        pinpad.commentLabel.isHidden = false
        pinpad.delegate = viewModel
        pinpad.modalPresentationStyle = .overFullScreen
        pinpad.backgroundView.backgroundColor = .adamant.backgroundColor
        pinpad.buttonsBackgroundColor = .adamant.backgroundColor
        
        pinpad.view.subviews.forEach { view in
            view.subviews.forEach { _view in
                if _view.backgroundColor == .white {
                    _view.backgroundColor = .adamant.backgroundColor
                }
            }
        }
        pinpad.commentLabel.backgroundColor = .adamant.backgroundColor
    }
    
    func pinpadEnable(_ isEnabled: Bool) {
        viewModel.pinpad.setColor(
            isEnabled
            ? .adamant.textColor.withAlphaComponent(0.8)
            : .lightGray,
            for: .normal
        )
        setButtonsEnabled(viewModel.pinpad.view, isEnabled: isEnabled)
    }
    
    func setButtonsEnabled(_ view: UIView, isEnabled: Bool) {
        view.subviews.forEach { subview in
            if let button = subview as? RoundedButton {
                button.isEnabled = isEnabled
            } else {
                setButtonsEnabled(subview, isEnabled: isEnabled)
            }
        }
    }
}
