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
	// MARK: Dependencies
	var router: Router!
	
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
						guard let vc = self?.router.get(scene: AdamantScene.Shared.shareQr) as? ShareQrViewController else {
							fatalError("Can't find ShareQrViewController")
						}
						
						vc.qrCode = qr
						vc.sharingTip = sharingTip
						vc.excludedActivityTypes = excludedActivityTypes
						self?.present(vc, animated: true, completion: completion)
						
					case .failure(error: let error):
						self?.showError(withMessage: String(describing: error))
					}
				})
				
			case .saveToPhotolibrary(let image):
				let action = UIAlertAction(title: type.localized, style: .default) { [weak self] _ in
					UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.image(_:didFinishSavingWithError:contextInfo:)), nil)
				}
				
				alert.addAction(action)
			}
		}
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		present(alert, animated: animated, completion: completion)
	}
	
	@objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
		if let error = error {
			showError(withMessage: error.localizedDescription)
		} else {
			showSuccess(withMessage: String.adamantLocalized.alert.done)
		}
	}
	
	func presentGoToSettingsAlert(title: String?, message: String?) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
			DispatchQueue.main.async {
				if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
					UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
				}
			}
		})
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		if Thread.isMainThread {
			present(alert, animated: true, completion: nil)
		} else {
			DispatchQueue.main.async { [weak self] in
				self?.present(alert, animated: true, completion: nil)
			}
		}
	}
}
