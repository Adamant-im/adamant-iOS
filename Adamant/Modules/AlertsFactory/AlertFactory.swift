//
//  AlertFactory.swift
//  Adamant
//
//  Created by Владимир Клевцов on 23.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import UIKit
import CommonKit

enum AlertFactory {
    @MainActor
    static func makeRenameAlert(
        titleFormat: String,
        placeholder: String,
        initialText: String?,
        onRename: @escaping (String) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: titleFormat,
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.autocapitalizationType = .words
            textField.text = initialText
        }
        
        let renameAction = UIAlertAction(
            title: "Rename",
            style: .default
        ) { _ in
            guard
                let textField = alert.textFields?.first,
                let newName = textField.text,
                !newName.isEmpty
            else { return }
            
            onRename(newName)
            AlertPresenter.freeTokenAlertIfNeed(type: .contacts)
        }
        
        alert.addAction(renameAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.modalPresentationStyle = .overFullScreen
        print("alert created")
        return alert
    }
}
