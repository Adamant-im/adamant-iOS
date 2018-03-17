//
//  QRGeneratorViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import EFQRCode
import Eureka
import Photos

// MARK: - Localization
extension String.adamantLocalized {
	struct qrGenerator {
		static let title = NSLocalizedString("QrGeneratorScene.Title", comment: "QRGenerator: scene title")
		
		static let tapToSaveTip = NSLocalizedString("QrGeneratorScene.TapToSave", comment: "QRGenerator: small 'Tap to save' tooltip under generated QR")
		static let passphrasePlaceholder = NSLocalizedString("QrGeneratorScene.Passphrase.Placeholder", comment: "QRGenerator: Passphrase textview placeholder")
		
		static let wrongPassphraseError = NSLocalizedString("QrGeneratorScene.Error.InvalidPassphrase", comment: "QRGenerator: user typed in wrong invalid")
		static let internalError = NSLocalizedString("QrGeneratorScene.Error.InternalErrorFormat", comment: "QRGenerator: Bad Internal generator error message format. Using %@ for error description")
		
		private init() {}
	}
}

// MARK: -
class QRGeneratorViewController: FormViewController {
	
	// MARK: Dependencies
	var dialogService: DialogService!
	
	private enum Rows {
		case qr
		case passphrase
		case generateButton
		
		var tag: String {
			switch self {
			case .qr: return "qr"
			case .passphrase: return "pp"
			case .generateButton: return "generate"
			}
		}
	}
	
	private enum Sections {
		case qr
		case passphrase
		
		var tag: String {
			switch self {
			case .qr: return "qrs"
			case .passphrase: return "pps"
			}
		}
	}
	
	
	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = String.adamantLocalized.qrGenerator.title
		navigationOptions = .Disabled
		
		self.tableView.showsVerticalScrollIndicator = false
		self.tableView.showsHorizontalScrollIndicator = false
		
		// MARK: QR section
		form +++ Section() { $0.tag = Sections.qr.tag }
		<<< QrRow() {
			$0.tag = Rows.qr.tag
			$0.cell.tipLabel.font = UIFont.adamantPrimary(size: 14)
			$0.cell.tipLabel.textColor = UIColor.adamantSecondary
			$0.cell.tipLabel.text = String.adamantLocalized.qrGenerator.tapToSaveTip
		}.onCellSelection({ [weak self] (cell, row) in
			if let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow {
				tableView.deselectRow(at: indexPath, animated: true)
			}
			
			guard let qr = row.value else {
				return
			}
			
			let vc = UIActivityViewController(activityItems: [qr], applicationActivities: nil)
			vc.excludedActivityTypes = ShareContentType.passphrase.excludedActivityTypes
			vc.completionWithItemsHandler = { (_, completed: Bool, _, error: Error?) in
				if completed {
					self?.dialogService.showToastMessage(String.adamantLocalized.alert.done)
				} else if let error = error {
					self?.dialogService.showToastMessage(String(describing: error))
				}
			}
			self?.present(vc, animated: true, completion: nil)
		})
		
		if let section = form.sectionBy(tag: Sections.qr.tag) {
			section.hidden = Condition.predicate(NSPredicate(format: "$\(Rows.qr.tag) == nil"))
			section.evaluateHidden()
		}
		
		// MARK: Passphrase section
		form +++ Section() { $0.tag = Sections.passphrase.tag }
		<<< TextAreaRow() {
			$0.placeholder = String.adamantLocalized.qrGenerator.passphrasePlaceholder
			$0.tag = Rows.passphrase.tag
			$0.textAreaHeight = .dynamic(initialTextViewHeight: 28.0) // 28 for textView and 8+8 for insets
		}.cellSetup({ (cell, row) in
			cell.textView?.textColor = UIColor.adamantPrimary
			cell.textView?.font = UIFont.adamantPrimary(size: 17)
			cell.placeholderLabel?.font = UIFont.adamantPrimary(size: 17)
		}).cellUpdate({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		})
		
		<<< ButtonRow() {
			$0.title = String.adamantLocalized.alert.generateQr
			$0.tag = Rows.generateButton.tag
		}.onCellSelection({ [weak self] (cell, row) in
			self?.generateQr()
		}).cellSetup({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
		}).cellUpdate({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		})
    }
	
	override func insertAnimation(forSections sections: [Section]) -> UITableViewRowAnimation {
		return .top
	}
	
	override func insertAnimation(forRows rows: [BaseRow]) -> UITableViewRowAnimation {
		return .top
	}
}


// MARK: - QR Tools
extension QRGeneratorViewController {
	func generateQr() {
		guard let row: TextAreaRow = form.rowBy(tag: Rows.passphrase.tag),
			let passphrase = row.value?.lowercased(), // Lowercased!
			AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
				dialogService.showToastMessage(String.adamantLocalized.qrGenerator.wrongPassphraseError)
			return
		}
		
		let encodedPassphrase = AdamantUriTools.encode(request: AdamantUri.passphrase(passphrase: passphrase))
		
		switch AdamantQRTools.generateQrFrom(string: encodedPassphrase) {
		case .success(let qr):
			setQr(image: qr)
			
		case .failure(let error):
			dialogService.showError(withMessage: String.localizedStringWithFormat(String.adamantLocalized.qrGenerator.internalError, String(describing: error)))
		}
	}
	
	func setQr(image: UIImage?) {
		guard let row: QrRow = form.rowBy(tag: Rows.qr.tag) else {
			return
		}
		
		guard let image = image else {
			row.value = nil
			return
		}
		
		row.value = image
		row.updateCell()
		
		form.sectionBy(tag: Sections.qr.tag)?.evaluateHidden()
	}
}
