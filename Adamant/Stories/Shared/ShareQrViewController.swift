//
//  ShareQrViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import Photos

extension String.adamantLocalized.shared {
	static let photolibraryNotAuthorized = NSLocalizedString("ShareQR.photolibraryNotAuthorized", comment: "ShareQR scene: User had not authorized access to write images to photolibrary")
}

class ShareQrViewController: FormViewController {
	// MARK: - Dependencies
	var dialogService: DialogService!
	
	
	// MARK: - Rows
	private enum Rows {
		case qr
		case saveToPhotos
		case shareButton
		case cancelButton
		
		var tag: String {
			switch self {
			case .qr: return "qr"
			case .saveToPhotos: return "svp"
			case .shareButton: return "sh"
			case .cancelButton: return "cl"
			}
		}
		
		var localized: String {
			switch self {
			case .qr:
				return ""
			
			case .saveToPhotos:
				return String.adamantLocalized.alert.saveToPhotolibrary
				
			case .shareButton:
				return String.adamantLocalized.alert.share
				
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
	
	var sharingTip: String? {
		didSet {
			if let row: QrRow = form.rowBy(tag: Rows.qr.tag) {
				if let tip = sharingTip {
					row.cell.tipLabelIsHidden = false
					row.cell.tipLabel.text = tip
				} else {
					row.cell.tipLabelIsHidden = true
				}
				row.updateCell()
				tableView.beginUpdates()
				tableView.endUpdates()
			}
		}
	}
	
	var excludedActivityTypes: [UIActivity.ActivityType]?
	
	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
        tableView.styles = ["baseTable"]
		
		// MARK: QR code
        let qrSection = Section()
        
		let qrRow = QrRow() {
			$0.value = qrCode
			$0.tag = Rows.qr.tag
			$0.cell.selectionStyle = .none
            $0.cell.style = "secondaryBackground"
			
			if let sharingTip = sharingTip {
				$0.cell.tipLabel.text = sharingTip
                $0.cell.tipLabel.style = "primaryText"
			} else {
				$0.cell.tipLabelIsHidden = true
			}
		}
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            qrRow.cell.height = { 450.0 }
        }
        
        qrSection.append(qrRow)
		
		// MARK: Buttons
		let buttonsSection = Section()
			
		// Photolibrary
		let photolibraryRow = ButtonRow() {
			$0.tag = Rows.saveToPhotos.tag
			$0.title = Rows.saveToPhotos.localized
		}.onCellSelection { [weak self] (cell, row) in
			guard let row: QrRow = self?.form.rowBy(tag: Rows.qr.tag), let qrCode = row.value else {
				return
			}
			
			switch PHPhotoLibrary.authorizationStatus() {
			case .authorized:
				UIImageWriteToSavedPhotosAlbum(qrCode, self, #selector(self?.image(_: didFinishSavingWithError: contextInfo:)), nil)
				
			case .notDetermined:
				UIImageWriteToSavedPhotosAlbum(qrCode, self, #selector(self?.image(_: didFinishSavingWithError: contextInfo:)), nil)
				
			case .restricted, .denied:
				self?.dialogService.presentGoToSettingsAlert(title: nil, message: String.adamantLocalized.shared.photolibraryNotAuthorized)
			}
		}.cellUpdate { (cell, row) in
			cell.textLabel?.textColor = UIColor.adamant.primary
            cell.style = "baseTableCell,secondaryBackground"
            cell.textLabel?.style = "primaryText"
		}
			
		// Share
		let shareRow = ButtonRow() {
			$0.tag = Rows.shareButton.tag
			$0.title = Rows.shareButton.localized
		}.onCellSelection { [weak self] (cell, row) in
			guard let row: QrRow = self?.form.rowBy(tag: Rows.qr.tag), let qrCode = row.value else {
				return
			}
			
			let vc = UIActivityViewController(activityItems: [qrCode], applicationActivities: nil)
			if let excludedActivityTypes = self?.excludedActivityTypes {
				vc.excludedActivityTypes = excludedActivityTypes
			}
            
            if let c = vc.popoverPresentationController {
                c.sourceView = cell
                c.sourceRect = cell.bounds
            }
			
			vc.completionWithItemsHandler = { [weak self] (type: UIActivity.ActivityType?, completed: Bool, _, error: Error?) in
				if completed {
					if let error = error {
						self?.dialogService.showWarning(withMessage: error.localizedDescription)
					} else {
						self?.dialogService.showSuccess(withMessage: String.adamantLocalized.alert.done)
					}
					self?.close()
				}
			}
			
			self?.present(vc, animated: true, completion: nil)
		}.cellUpdate { (cell, row) in
			cell.textLabel?.textColor = UIColor.adamant.primary
            cell.style = "baseTableCell,secondaryBackground"
            cell.textLabel?.style = "primaryText"
		}
		
		let cancelRow = ButtonRow() {
			$0.tag = Rows.cancelButton.tag
			$0.title = Rows.cancelButton.localized
		}.onCellSelection { [weak self] (cell, row) in
			self?.close()
		}.cellUpdate { (cell, row) in
			cell.textLabel?.textColor = UIColor.adamant.primary
            cell.style = "baseTableCell,secondaryBackground"
            cell.textLabel?.style = "primaryText"
		}
        
        buttonsSection.append(contentsOf: [photolibraryRow, shareRow, cancelRow])
        
        form.append(contentsOf: [qrSection, buttonsSection])
	}
	
	func close() {
		if let nav = navigationController {
			nav.popViewController(animated: true)
		} else {
			dismiss(animated: true, completion: nil)
		}
	}
	
	@objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
		if error != nil {
			dialogService.presentGoToSettingsAlert(title: String.adamantLocalized.shared.photolibraryNotAuthorized, message: nil)
		} else {
			dialogService.showSuccess(withMessage: String.adamantLocalized.alert.done)
			close()
		}
	}
}

extension ShareQrViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIColor.adamant.statusBar
    }
}
