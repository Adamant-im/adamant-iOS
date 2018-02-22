//
//  ShareQrViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class ShareQrViewController: FormViewController {
	private enum Rows {
		case qr
		case saveButton
		case cancelButton
		
		var tag: String {
			switch self {
			case .qr: return "qr"
			case .saveButton: return "sv"
			case .cancelButton: return "cl"
			}
		}
		
		var localized: String {
			switch self {
			case .qr:
				return ""
			
			case .saveButton:
				return String.adamantLocalized.alert.save
				
			case .cancelButton:
				return String.adamantLocalized.alert.cancel
			}
		}
	}
	
	// MARK: - Properties
	var qrCode: UIImage? {
		didSet {
			if let row: QrRow = form.rowBy(tag: Rows.qr.tag) {
				row.value = qrCode
			}
		}
	}
	
	var excludedActivityTypes: [UIActivityType]?
	
	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// MARK: QR code
		form +++ Section()
		<<< QrRow() {
			$0.value = qrCode
			$0.tag = Rows.qr.tag
			$0.cell.tipLabelIsHidden = true
		}
		
		// MARK: Buttons
		+++ Section()
		<<< ButtonRow() {
			$0.tag = Rows.saveButton.tag
			$0.title = Rows.saveButton.localized
		}.onCellSelection({ [weak self] (cell, row) in
			guard let row: QrRow = self?.form.rowBy(tag: Rows.qr.tag), let qrCode = row.value else {
				return
			}
			
			let vc = UIActivityViewController(activityItems: [qrCode], applicationActivities: nil)
			if let excludedActivityTypes = self?.excludedActivityTypes {
				vc.excludedActivityTypes = excludedActivityTypes
			}
			
			vc.completionWithItemsHandler = { [weak self] (_, success: Bool, _, _) in
				if success {
					self?.close()
				}
			}
			
			self?.present(vc, animated: true, completion: nil)
		}).cellSetup({ (cell, row) in
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
			cell.textLabel?.textColor = UIColor.adamantPrimary
		}).cellUpdate({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		})
		
		<<< ButtonRow() {
			$0.tag = Rows.cancelButton.tag
			$0.title = Rows.cancelButton.localized
		}.onCellSelection({ [weak self] (cell, row) in
			self?.close()
		}).cellSetup({ (cell, row) in
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
			cell.textLabel?.textColor = UIColor.adamantPrimary
		}).cellUpdate({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		})
	}
	
	func close() {
		if let nav = navigationController {
			nav.popViewController(animated: true)
		} else {
			dismiss(animated: true, completion: nil)
		}
	}
}
