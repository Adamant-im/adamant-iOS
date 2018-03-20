//
//  AdamantDialogService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FTIndicator

class AdamantDialogService: DialogService {
	// Configure notifications
	init() {
		FTIndicator.setIndicatorStyle(.extraLight)
	}
}


// MARK: - Modal dialogs
extension AdamantDialogService {
	func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
		if Thread.isMainThread {
			AdamantDialogService.getTopmostViewController()?.present(viewController, animated: animated, completion: completion)
		} else {
			DispatchQueue.main.async {
				AdamantDialogService.getTopmostViewController()?.present(viewController, animated: animated, completion: completion)
			}
		}
	}
	
	private static func getTopmostViewController() -> UIViewController? {
		if var topController = UIApplication.shared.keyWindow?.rootViewController {
			while let presentedViewController = topController.presentedViewController {
				topController = presentedViewController
			}
			
			return topController
		}
		
		return nil
	}
}


// MARK: - Toast
extension AdamantDialogService {
	func showToastMessage(_ message: String) {
		FTIndicator.showToastMessage(message)
	}
	
	func dismissToast() {
		FTIndicator.dismissToast()
	}
}


// MARK: - Indicators
extension AdamantDialogService {
	func showProgress(withMessage message: String?, userInteractionEnable enabled: Bool) {
		FTIndicator.showProgress(withMessage: message, userInteractionEnable: enabled)
	}
	
	func dismissProgress() {
		if Thread.isMainThread {
			FTIndicator.dismissProgress()
		} else {
			DispatchQueue.main.async {
				FTIndicator.dismissProgress()
			}
		}
	}
	
	func showSuccess(withMessage message: String) {
		FTIndicator.showSuccess(withMessage: message)
	}
	
	func showError(withMessage message: String) {
		FTIndicator.showError(withMessage: message)
	}
}


// MAKR: - Activity controllers
extension AdamantDialogService {
	func presentShareAlertFor(string: String, types: [ShareType], excludedActivityTypes: [UIActivityType]?, animated: Bool, completion: (() -> Void)?) {
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		for type in types {
			switch type {
			case .copyToPasteboard:
				alert.addAction(UIAlertAction(title: type.localized , style: .default) { [weak self] _ in
					UIPasteboard.general.string = string
					self?.showToastMessage(String.adamantLocalized.alert.copiedToPasteboardNotification)
				})
				
			case .share:
				alert.addAction(UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
					let vc = UIActivityViewController(activityItems: [string], applicationActivities: nil)
					vc.excludedActivityTypes = excludedActivityTypes
					self?.present(vc, animated: true, completion: completion)
				})
				
			case .generateQr(let sharingTip):
				alert.addAction(UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
					switch AdamantQRTools.generateQrFrom(string: string) {
					case .success(let qr):
						let vc = ShareQrViewController(nibName: "ShareQrViewController", bundle: nil)
						vc.qrCode = qr
						vc.sharingTip = sharingTip
						vc.excludedActivityTypes = excludedActivityTypes
						self?.present(vc, animated: true, completion: completion)
						
					case .failure(error: let error):
						self?.showError(withMessage: String(describing: error))
					}
				})
			}
		}
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		present(alert, animated: animated, completion: completion)
	}
}
