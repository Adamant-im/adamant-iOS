//
//  PKGeneratorViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import EFQRCode
import Eureka
import Photos
import MarkdownKit

// MARK: - Localization
extension String.adamantLocalized {
    struct pkGenerator {
        static let title = NSLocalizedString("PkGeneratorScene.Title", comment: "PrivateKeyGenerator: scene title")
        static let alert = NSLocalizedString("PkGeneratorScene.Alert", comment: "PrivateKeyGenerator: Security alert. Keep your passphrase safe")
        static let generateButton = NSLocalizedString("PkGeneratorScene.GenerateButton", comment: "PrivateKeyGenerator: Generate button")
        
        private init() {}
    }
}

// MARK: -
class PKGeneratorViewController: FormViewController {
    
    // MARK: Dependencies
    var accountService: AccountService!
    var dialogService: DialogService!
    
    private enum Rows {
        case alert
        case passphrase
        case generateButton
        
        var tag: String {
            switch self {
            case .alert: return "alrt"
            case .passphrase: return "pp"
            case .generateButton: return "generate"
            }
        }
    }
    
    private enum Sections {
        case privateKeys
        case passphrase
        
        var tag: String {
            switch self {
            case .privateKeys: return "pks"
            case .passphrase: return "pps"
            }
        }
    }
    
    // MARK: - Properties
    private var showKeysSection = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        navigationItem.title = String.adamantLocalized.pkGenerator.title
        navigationOptions = .Disabled
        
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        
        // MARK: PrivateKeys section
        let pkSection = Section {
            $0.tag = Sections.privateKeys.tag
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let show = self?.showKeysSection else {
                    return true
                }
                
                return !show
            })
        }
        
        // MARK: Passphrase section
        let passphraseSection = Section { $0.tag = Sections.passphrase.tag }
        
        let alertRow = TextAreaRow {
            $0.tag = Rows.alert.tag
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
        }.cellUpdate { (cell, _) in
            cell.textView.textAlignment = .center
            cell.textView.isSelectable = false
            cell.textView.isEditable = false
            
            let parser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize), color: UIColor.adamant.primary)
            
            let style = NSMutableParagraphStyle()
            style.alignment = NSTextAlignment.center
            
            let mutableText = NSMutableAttributedString(attributedString: parser.parse(String.adamantLocalized.pkGenerator.alert))
            mutableText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: mutableText.length))
            
            cell.textView.attributedText = mutableText
        }
        
        let passphraseRow = TextAreaRow {
            $0.placeholder = String.adamantLocalized.qrGenerator.passphrasePlaceholder
            $0.tag = Rows.passphrase.tag
            $0.textAreaHeight = .dynamic(initialTextViewHeight: 28.0) // 28 for textView and 8+8 for insets
        }
            
        let generateButton = ButtonRow {
            $0.title = String.adamantLocalized.pkGenerator.generateButton
            $0.tag = Rows.generateButton.tag
        }.onCellSelection { [weak self] (_, row) in
            guard let row: TextAreaRow = self?.form.rowBy(tag: Rows.passphrase.tag), let passphrase = row.value else {
                return
            }
            
            self?.generatePKKeys(for: passphrase)
        }
        
        passphraseSection.append(contentsOf: [alertRow, passphraseRow, generateButton])
        
        form.append(contentsOf: [pkSection, passphraseSection])
        
        setColors()
    }
    
    // MARK: - Other
    
    func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
    
    // MARK: - PrivateKey tools
    private func generatePKKeys(for passphrase: String) {
        guard let section = form.sectionBy(tag: Sections.privateKeys.tag) else {
            return
        }
        
        section.removeAll()
        
        let passphraseLower = passphrase.lowercased()
        
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphraseLower) else {
            dialogService.showToastMessage(String.adamantLocalized.qrGenerator.wrongPassphraseError)
            return
        }
        
        var index = 0
        var rows = [LabelRow]()
        for case let generator as PrivateKeyGenerator in accountService.wallets {
            guard let privateKey = generator.generatePrivateKeyFor(passphrase: passphraseLower) else {
                continue
            }
            
            let row = LabelRow {
                $0.tag = "row\(index)"
                index += 1
                $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
                $0.cell.selectionStyle = .gray
                
                $0.title = generator.rowTitle
                $0.value = privateKey
                $0.cell.imageView?.image = generator.rowImage?.withRenderingMode(.alwaysTemplate)
            }.cellUpdate { (cell, _) in
                cell.accessoryType = .disclosureIndicator
            }.onCellSelection { [weak self] (cell, row) in
                guard let passphrase = row.value, let dialogService = self?.dialogService else {
                    return
                }
                
                let encodedPassphrase = AdamantUriTools.encode(request: AdamantUri.passphrase(passphrase: passphrase))
                dialogService.presentShareAlertFor(string: passphrase,
                                                   types: [.copyToPasteboard,
                                                           .share,
                                                           .generateQr(encodedContent: encodedPassphrase, sharingTip: nil, withLogo: false)],
                                                   excludedActivityTypes: ShareContentType.passphrase.excludedActivityTypes,
                                                   animated: true, from: cell,
                                                   completion: {
                                                    if let indexPath = row.indexPath, let tableView = self?.tableView {
                                                        tableView.deselectRow(at: indexPath, animated: true)
                                                    }
                                                    })
            }
            
            rows.append(row)
        }
        
        showKeysSection = rows.count > 0
        section.append(contentsOf: rows)
        section.evaluateHidden()
    }
}
