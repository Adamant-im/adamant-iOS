//
//  PartnerQRViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import Combine
import CommonKit
import Photos

@MainActor
final class PartnerQRViewModel: NSObject, ObservableObject {
    @Published var includeContactsNameEnabled = true
    @Published var image: UIImage?
    @Published var partnerImage: UIImage?
    @Published var partnerName: String = ""
    @Published var renameTitle: String = ""
    @Published var includeWebAppLink = false
    @Published var includeContactsName = false
    
    private var partner: CoreDataAccount?
    private let dialogService: DialogService
    private let addressBookService: AddressBookService
    private let avatarService: AvatarService
    private let partnerQRService: PartnerQRService
    private var subscriptions = Set<AnyCancellable>()
    
    let partnerImageSize: CGFloat = 25
    
    var title: String {
        partner?.address ?? ""
    }
    
    init(
        dialogService: DialogService,
        addressBookService: AddressBookService,
        avatarService: AvatarService,
        partnerQRService: PartnerQRService
    ) {
        self.dialogService = dialogService
        self.addressBookService = addressBookService
        self.avatarService = avatarService
        self.partnerQRService = partnerQRService
    }
    
    func setup(partner: CoreDataAccount) {
        self.partner = partner
        updatePartnerInfo()
        generateQR()
    }
    
    func renameContact() {
        guard let alert = self.makeRenameAlert(for: self.title) else { return }
        self.dialogService.present(alert, animated: true) {
            self.dialogService.selectAllTextFields(in: alert)
        }
    }
    
    func saveToPhotos() {
        guard let qrCode = image else { return }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            UIImageWriteToSavedPhotosAlbum(
                qrCode,
                self,
                #selector(image(_: didFinishSavingWithError: contextInfo:)),
                nil
            )
            
        case .notDetermined:
            UIImageWriteToSavedPhotosAlbum(
                qrCode,
                self,
                #selector(image(_: didFinishSavingWithError: contextInfo:)),
                nil
            )
            
        case .restricted, .denied:
            dialogService.presentGoToSettingsAlert(
                title: nil,
                message: String.adamant.shared.photolibraryNotAuthorized
            )
        @unknown default:
            break
        }
    }

    func share() {
        guard let qrCode = image else { return }

        let vc = UIActivityViewController(
            activityItems: [qrCode],
            applicationActivities: nil
        )
        
        vc.completionWithItemsHandler = { [weak self] (_: UIActivity.ActivityType?, completed: Bool, _, error: Error?) in
            guard completed else { return }
            
            if let error = error {
                self?.dialogService.showWarning(withMessage: error.localizedDescription)
            } else {
                self?.dialogService.showSuccess(withMessage: String.adamant.alert.done)
            }
        }
        vc.modalPresentationStyle = .overFullScreen
        dialogService.present(vc, animated: true, completion: nil)
    }
    
    func didToggle() {
        partnerQRService.setIncludeURLEnabled(includeWebAppLink)
        partnerQRService.setIncludeNameEnabled(includeContactsName)
        generateQR()
    }
    
    func copyToPasteboard() {
        UIPasteboard.general.string = title
        dialogService.showToastMessage(.adamant.alert.copiedToPasteboardNotification)
    }
}

private extension PartnerQRViewModel {
    func updatePartnerInfo() {
        guard let publicKey = partner?.publicKey,
              let address = partner?.address
        else {
            includeContactsNameEnabled = false
            includeContactsName = false
            includeWebAppLink = false
            return
        }
        
        let name = addressBookService.getName(for: partner)
        
        if let name = name {
            partnerName = name
            includeContactsNameEnabled = true
            includeContactsName = partnerQRService.isIncludeNameEnabled()
            renameTitle = .adamant.alert.renameContact
        } else {
            partnerName = address
            includeContactsNameEnabled = false
            includeContactsName = false
            renameTitle = .adamant.alert.renameContactInitial
        }
        
        includeWebAppLink = partnerQRService.isIncludeURLEnabled()
        
        guard let avatarName = partner?.avatar,
              let avatar = UIImage.asset(named: avatarName)
        else {
            partnerImage = avatarService.avatar(
                for: publicKey,
                size: partnerImageSize
            )
            return
        }
        
        partnerImage = avatar
    }
    
    func generateQR() {
        guard let address = partner?.address else { return }
        
        var params: [AdamantAddressParam] = []
        
        let name = addressBookService.getName(for: partner)
        
        if includeContactsName,
           let name = name {
            params.append(.label(name))
        }
        
        var data: String = address
        
        if includeWebAppLink {
            data = AdamantUriTools.encode(request: AdamantUri.address(
                address: address,
                params: params
            ))
        } else {
            data = AdamantUriTools.encode(request: AdamantUri.addressLegacy(
                address: address,
                params: params
            ))
        }
        
        let qr = AdamantQRTools.generateQrFrom(
            string: data,
            withLogo: true
        )
        
        switch qr {
        case .success(let uIImage):
            image = uIImage
        case .failure(let error):
            dialogService.showError(withMessage: "", supportEmail: false, error: error)
        }
    }
    
    @objc private func image(
        _ image: UIImage,
        didFinishSavingWithError error: NSError?,
        contextInfo: UnsafeRawPointer
    ) {
        guard error == nil else {
            dialogService.presentGoToSettingsAlert(title: String.adamant.shared.photolibraryNotAuthorized, message: nil)
            return
        }
        
        dialogService.showSuccess(withMessage: String.adamant.alert.done)
    }

    func makeRenameAlert(for address: String) -> UIAlertController? {
        let alert = UIAlertController(
            title: .init(format: .adamant.chat.actionsBody, address),
            message: nil,
            preferredStyleSafe: .alert,
            source: nil
        )
        
        alert.addTextField { [weak self] textField in
            textField.placeholder = .adamant.chat.name
            textField.autocapitalizationType = .words
            textField.text = self?.addressBookService.getName(for: address)
        }
        
        let renameAction = UIAlertAction(
            title: .adamant.chat.rename,
            style: .default
        ) { [weak self] _ in
            guard
                let textField = alert.textFields?.first,
                let newName = textField.text
            else { return }
            
            Task {
                self?.partnerName = newName
                self?.renameTitle = .adamant.alert.renameContact
                await self?.addressBookService.set(name: newName, for: address)
            }
        }
        
        alert.addAction(renameAction)
        alert.addAction(makeCancelAction())
        alert.modalPresentationStyle = .overFullScreen
        return alert
    }
    
    func makeCancelAction() -> UIAlertAction {
        .init(title: .adamant.alert.cancel, style: .cancel, handler: nil)
    }
}
