//
//  ChatDialog.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import ElegantEmojiPicker

enum ChatDialog {
    case toast(String)
    case alert(String)
    case error(String, supportEmail: Bool)
    case warning(String)
    case richError(Error)
    case freeTokenAlert
    case removeMessageAlert(id: String)
    case reportMessageAlert(id: String)
    case menu(sender: UIBarButtonItem)
    case admMenu(AdamantAddress, partnerAddress: String)
    case dummy(String)
    case url(URL)
    case progress(Bool)
    case failedMessageAlert(id: String, sender: UIAlertController.SourceView?)
    case presentMenu(
        presentReactions: Bool,
        arg: ChatContextMenuArguments,
        didSelectEmojiDelegate: ElegantEmojiPickerDelegate?,
        didSelectEmojiAction: ChatDialogManager.DidSelectEmojiAction,
        didPresentMenuAction: ChatDialogManager.ContextMenuAction,
        didDismissMenuAction: ChatDialogManager.ContextMenuAction
    )
    case dismissMenu
    case renameAlert
    case actionMenu
    case noActiveNodesAlert(nodeName: String, action: ChatDialogManager.NoActiveNodesAction)
}
