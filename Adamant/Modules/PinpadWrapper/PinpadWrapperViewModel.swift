//
//  PinpadWrapperViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 15.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import Combine
import MyLittlePinpad
import CommonKit

final class PinpadWrapperViewModel {
    private let accountService: AccountService
    private let localAuth: LocalAuthentication
    private var subscriptions = Set<AnyCancellable>()
    
    let successAction = ObservableSender<Void>()
    let pinpadEnable = ObservableSender<Bool>()
    
    let pinpad: PinpadViewController
    
    init(
        accountService: AccountService,
        localAuth: LocalAuthentication
    ) {
        self.accountService = accountService
        self.localAuth = localAuth
        
        let button: PinpadBiometryButtonType = accountService.useBiometry
        ? localAuth.biometryType.pinpadButtonType
        : .hidden
        
        pinpad = PinpadViewController.adamantPinpad(biometryButton: button)
        setupObservers()
    }
}

private extension PinpadWrapperViewModel {
    func setupObservers() {
        accountService.remainingAttemptsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.pinpad.commentLabel.text = "\(String.adamant.login.loginIntoPrevAccount)\nAttempts remaining: \(value)"
                
                self?.pinpadEnable.send(value > .zero)
            }
            .store(in: &subscriptions)
        
        accountService.remainingTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                let time = value > .zero
                ? "\nEntering the code unlocks after \(Int(value)) seconds"
                : .empty
                
                self?.pinpad.commentLabel.text = "\(String.adamant.login.loginIntoPrevAccount)\(time)"
            }
            .store(in: &subscriptions)
    }
}

extension PinpadWrapperViewModel: PinpadViewControllerDelegate {
    func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
        guard accountService.hasStayInAccount else {
            return
        }
        
        guard (try? accountService.validatePin(pin)) == true else {
            pinpad.clearPin()
            pinpad.playWrongPinAnimation()
            return
        }
        
        successAction.send()
    }
    
    func pinpadDidTapBiometryButton(_ pinpad: PinpadViewController) {
        localAuth.authorizeUser(
            reason: .adamant.login.loginIntoPrevAccount,
            completion: { [weak self] result in
            guard case .success = result else { return }
            
            self?.successAction.send()
        })
    }
    
    func pinpadDidCancel(_ pinpad: PinpadViewController) {
        pinpad.dismiss(animated: true, completion: nil)
    }
}
