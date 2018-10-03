//
//  TransferViewControllerBase+Alert.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension TransferViewControllerBase {
	
	// MARK: - Progress view
	func showProgressView(animated: Bool) {
		if let alertView = alertView {
			hideView(alertView, animated: animated)
		}
		
		guard progressView == nil else {
			return
		}
		
		let view = UIView()
		progressView = view
		view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
		self.view.addSubview(view)
		self.view.constrainToEdges(view)
		
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
		view.addSubview(indicator)
		view.constrainCentered(indicator)
		indicator.startAnimating()
		
		if animated {
			if Thread.isMainThread {
				view.alpha = 0
				UIView.animate(withDuration: 0.2) {
					view.alpha = 1
				}
			} else {
				DispatchQueue.main.async {
					view.alpha = 0
					UIView.animate(withDuration: 0.2) {
						view.alpha = 1
					}
				}
			}
		}
	}
	
	func hideProgress(animated: Bool) {
		guard let progressView = progressView else {
			return
		}
		
		hideView(progressView, animated: animated)
	}
	
	
	// MARK: - Alert view
	
	func showAlertView(title: String?, message: String, animated: Bool) {
		if let progressView = progressView {
			hideView(progressView, animated: animated)
		}
		
		if let alertView = alertView {
			hideView(alertView, animated: animated)
		}
		
		let callback = {
			guard let alert = UINib(nibName: "FullscreenAlertView", bundle: nil).instantiate(withOwner: nil).first as? FullscreenAlertView else {
				fatalError("Can't get FullscreenAlertView")
			}
			
			alert.title = title
			alert.message = message
			
			self.view.addSubview(alert)
			self.view.constrainToEdges(alert)
			
			if animated {
				alert.alpha = 0
				alert.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
				
				UIView.animate(withDuration: 0.2) {
					alert.alpha = 1
					alert.transform = CGAffineTransform(scaleX: 1, y: 1)
				}
			}
		}
		
		if Thread.isMainThread {
			callback()
		} else {
			DispatchQueue.main.async {
				callback()
			}
		}
	}
	
	func hideAlert(animated: Bool) {
		guard let alertView = alertView else {
			return
		}
		
		hideView(alertView, animated: animated)
	}
	
	
	// MARK: - Tools
	private func hideView(_ view: UIView, animated: Bool) {
		let callback: () -> Void
		
		if animated {
			callback = {
				UIView.animate(withDuration: 0.2, animations: {
					view.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
				}, completion: { success in
					view.removeFromSuperview()
				})
			}
		} else {
			callback = {
				view.removeFromSuperview()
			}
		}
		
		if Thread.isMainThread {
			callback()
		} else {
			DispatchQueue.main.async {
				callback()
			}
		}
	}
}
