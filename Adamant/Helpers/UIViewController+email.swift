//
//  UIViewController+email.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.10.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageUI
import UIKit

extension UIViewController {
    func openEmailScreen(
        recipient: String,
        subject: String,
        body: String,
        delegate: MFMailComposeViewControllerDelegate?
    ) {
        if MFMailComposeViewController.canSendMail() {
            showEmailVC(recipient: recipient, subject: subject, body: body, delegate: delegate)
        } else {
            AdamantUtilities.openEmailApp(recipient: recipient, subject: subject, body: body)
        }
    }
}

private extension UIViewController {
    func showEmailVC(
        recipient: String,
        subject: String,
        body: String,
        delegate: MFMailComposeViewControllerDelegate?
    ) {
        let html = body.replacingOccurrences(of: "\n", with: "<br>")
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = delegate
        mailVC.setToRecipients([recipient])
        mailVC.setSubject(subject)
        mailVC.setMessageBody(html, isHTML: true)
        mailVC.modalPresentationStyle = .overFullScreen
        present(mailVC, animated: true, completion: nil)
    }
}
