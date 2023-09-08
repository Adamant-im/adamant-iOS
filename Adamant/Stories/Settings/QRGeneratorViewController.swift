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
import CommonKit

// MARK: - Localization
extension String.adamant {
    struct qrGenerator {
        static let title = String.localized("QrGeneratorScene.Title", comment: "QRGenerator: scene title")
        
        static let tapToSaveTip = String.localized("QrGeneratorScene.TapToSave", comment: "QRGenerator: small 'Tap to save' tooltip under generated QR")
        static let passphrasePlaceholder = String.localized("QrGeneratorScene.Passphrase.Placeholder", comment: "QRGenerator: Passphrase textview placeholder")
        
        static let wrongPassphraseError = String.localized("QrGeneratorScene.Error.InvalidPassphrase", comment: "QRGenerator: user typed in invalid passphrase")
        static let internalError = String.localized("QrGeneratorScene.Error.InternalErrorFormat", comment: "QRGenerator: Bad Internal generator error message format. Using %@ for error description")
        
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
        
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = String.adamant.qrGenerator.title
        navigationOptions = .Disabled
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        // MARK: QR section
        form +++ Section { $0.tag = Sections.qr.tag }
        <<< QrRow {
            $0.tag = Rows.qr.tag
            $0.cell.tipLabel.text = String.adamant.qrGenerator.tapToSaveTip
        }.onCellSelection { [weak self] (cell, row) in
            if let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            guard let qr = row.value else {
                return
            }
            
            let save = UIAlertAction(title: String.adamant.alert.saveToPhotolibrary, style: .default, handler: { _ in
                
                switch PHPhotoLibrary.authorizationStatus() {
                case .authorized, .limited:
                    UIImageWriteToSavedPhotosAlbum(qr, self, #selector(self?.image(_: didFinishSavingWithError: contextInfo:)), nil)
                    
                case .notDetermined:
                    UIImageWriteToSavedPhotosAlbum(qr, self, #selector(self?.image(_: didFinishSavingWithError: contextInfo:)), nil)
                    
                case .restricted, .denied:
                    self?.dialogService.presentGoToSettingsAlert(title: nil, message: String.adamant.shared.photolibraryNotAuthorized)
                @unknown default:
                    break
                }
            })
            
            let share = UIAlertAction(title: String.adamant.alert.share, style: .default, handler: { _ in
                let vc = UIActivityViewController(activityItems: [qr], applicationActivities: nil)
                vc.excludedActivityTypes = ShareContentType.passphrase.excludedActivityTypes
                vc.completionWithItemsHandler = { (_, completed: Bool, _, error: Error?) in
                    if completed {
                        self?.dialogService.showToastMessage(String.adamant.alert.done)
                    } else if let error = error {
                        self?.dialogService.showToastMessage(error.localizedDescription)
                    }
                }
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: true, completion: nil)
            })
            
            let cancel = UIAlertAction(title: String.adamant.alert.cancel, style: .cancel, handler: nil)
            
            let alert = UIAlertController(
                title: nil,
                message: nil,
                preferredStyleSafe: .actionSheet,
                source: .view(cell)
            )
            
            alert.addAction(save)
            alert.addAction(share)
            alert.addAction(cancel)
            alert.modalPresentationStyle = .overFullScreen
            self?.present(alert, animated: true, completion: nil)
        }
        
        if let section = form.sectionBy(tag: Sections.qr.tag) {
            section.hidden = Condition.predicate(NSPredicate(format: "$\(Rows.qr.tag) == nil"))
            section.evaluateHidden()
        }
        
        // MARK: Passphrase section
        form +++ Section { $0.tag = Sections.passphrase.tag }
        <<< PasswordRow {
            $0.placeholder = String.adamant.qrGenerator.passphrasePlaceholder
            $0.cell.textField.enablePasswordToggle()
            $0.tag = Rows.passphrase.tag
        }
        
        <<< ButtonRow {
            $0.title = String.adamant.alert.generateQr
            $0.tag = Rows.generateButton.tag
        }.onCellSelection { [weak self] (_, _) in
            self?.generateQr()
        }
        
        setColors()
    }
    
    override func insertAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
        return .top
    }
    
    override func insertAnimation(forRows rows: [BaseRow]) -> UITableView.RowAnimation {
        return .top
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            dialogService.presentGoToSettingsAlert(title: String.adamant.shared.photolibraryNotAuthorized, message: nil)
        } else {
            dialogService.showSuccess(withMessage: String.adamant.alert.done)
        }
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
}

// MARK: - QR Tools
extension QRGeneratorViewController {
    func generateQr() {
        guard let row: TextAreaRow = form.rowBy(tag: Rows.passphrase.tag),
            let passphrase = row.value?.lowercased(), // Lowercased!
            AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
                dialogService.showToastMessage(String.adamant.qrGenerator.wrongPassphraseError)
            return
        }
        
        let encodedPassphrase = AdamantUriTools.encode(request: AdamantUri.passphrase(passphrase: passphrase))
        
        switch AdamantQRTools.generateQrFrom(string: encodedPassphrase) {
        case .success(let qr):
            setQr(image: qr)
            
        case .failure(let error):
            dialogService.showError(withMessage: String.localizedStringWithFormat(String.adamant.qrGenerator.internalError, error.localizedDescription), supportEmail: true, error: error)
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
