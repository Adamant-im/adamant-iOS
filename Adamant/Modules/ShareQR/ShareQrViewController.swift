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
import CommonKit

extension String.adamant.shared {
    static var photolibraryNotAuthorized: String { String.localized("ShareQR.photolibraryNotAuthorized", comment: "ShareQR scene: User had not authorized access to write images to photolibrary")
    }
}

final class ShareQrViewController: FormViewController {
    // MARK: - Dependencies
    private let dialogService: DialogService
    
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
                return String.adamant.alert.saveToPhotolibrary
                
            case .shareButton:
                return String.adamant.alert.share
                
            case .cancelButton:
                return String.adamant.alert.cancel
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
    
    init(dialogService: DialogService) {
        self.dialogService = dialogService
        super.init(nibName: "ShareQrViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: QR code
        let qrSection = Section()
        
        let qrRow = QrRow {
            $0.value = qrCode
            $0.tag = Rows.qr.tag
            $0.cell.selectionStyle = .none
            
            if let sharingTip = sharingTip {
                $0.cell.tipLabel.text = sharingTip
                $0.cell.tipLabel.lineBreakMode = .byTruncatingMiddle
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
        let photolibraryRow = ButtonRow {
            $0.tag = Rows.saveToPhotos.tag
            $0.title = Rows.saveToPhotos.localized
        }.onCellSelection { [weak self] (_, row) in
            guard let row: QrRow = self?.form.rowBy(tag: Rows.qr.tag), let qrCode = row.value else {
                return
            }
            
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized, .limited:
                UIImageWriteToSavedPhotosAlbum(qrCode, self, #selector(self?.image(_: didFinishSavingWithError: contextInfo:)), nil)
                
            case .notDetermined:
                UIImageWriteToSavedPhotosAlbum(qrCode, self, #selector(self?.image(_: didFinishSavingWithError: contextInfo:)), nil)
                
            case .restricted, .denied:
                self?.dialogService.presentGoToSettingsAlert(title: nil, message: String.adamant.shared.photolibraryNotAuthorized)
            @unknown default:
                break
            }
        }
            
        // Share
        let shareRow = ButtonRow {
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
            
            vc.completionWithItemsHandler = { [weak self] (_: UIActivity.ActivityType?, completed: Bool, _, error: Error?) in
                if completed {
                    if let error = error {
                        self?.dialogService.showWarning(withMessage: error.localizedDescription)
                    } else {
                        self?.dialogService.showSuccess(withMessage: String.adamant.alert.done)
                    }
                    self?.close()
                }
            }
            vc.modalPresentationStyle = .overFullScreen
            self?.present(vc, animated: true, completion: nil)
        }
        
        let cancelRow = ButtonRow {
            $0.tag = Rows.cancelButton.tag
            $0.title = Rows.cancelButton.localized
        }.onCellSelection { [weak self] (_, _) in
            self?.close()
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
            dialogService.presentGoToSettingsAlert(title: String.adamant.shared.photolibraryNotAuthorized, message: nil)
        } else {
            dialogService.showSuccess(withMessage: String.adamant.alert.done)
            close()
        }
    }
}
