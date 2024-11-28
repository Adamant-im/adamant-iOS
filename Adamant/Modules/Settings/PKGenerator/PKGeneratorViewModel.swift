//
//  PKGeneratorViewModel.swift
//  Adamant
//
//  Created by Andrew G on 28.11.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import Combine
import CommonKit
import MarkdownKit

// MARK: - Localization
extension String.adamant {
    enum pkGenerator {
        static var title: String {
            .localized(
                "PkGeneratorScene.Title",
                comment: "PrivateKeyGenerator: scene title"
            )
        }
        static var alert: String {
            .localized(
                "PkGeneratorScene.Alert",
                comment: "PrivateKeyGenerator: Security alert. Keep your passphrase safe"
            )
        }
        static var generateButton: String {
            .localized(
                "PkGeneratorScene.GenerateButton",
                comment: "PrivateKeyGenerator: Generate button"
            )
        }
        
        static func keyFormat(_ format: String) -> String {
            .localizedStringWithFormat(
                .localized(
                    "PkGeneratorScene.KeyFormat",
                    comment: "PrivateKeyGenerator: key format"
                ),
                format
            )
        }
    }
}

@MainActor
final class PKGeneratorViewModel: ObservableObject {
    @Published var state: PKGeneratorState = .default
    
    private let dialogService: DialogService
    private let walletServiceCompose: WalletServiceCompose
    
    nonisolated init(
        dialogService: DialogService,
        walletServiceCompose: WalletServiceCompose
    ) {
        self.dialogService = dialogService
        self.walletServiceCompose = walletServiceCompose
        Task { @MainActor in configure() }
    }
    
    func onTap(key: String) {
        dialogService.presentShareAlertFor(
            string: key,
            types: [
                .copyToPasteboard,
                .share,
                .generateQr(
                    encodedContent: key,
                    sharingTip: nil,
                    withLogo: false
                )
            ],
            excludedActivityTypes: ShareContentType.passphrase.excludedActivityTypes,
            animated: true,
            from: Optional<UIView>.none,
            completion: nil
        )
    }
    
    func generateKeys() {
        guard !state.isLoading else { return }
        withAnimation { state.isLoading = true }
        let passphrase = state.passphrase.lowercased()
        
        Task {
            defer { withAnimation { state.isLoading = false } }
            
            do {
                let keys = try await Task.detached { [walletServiceCompose] in
                    try generatePrivateKeys(
                        passphrase: passphrase,
                        walletServiceCompose: walletServiceCompose
                    )
                }.value
                
                withAnimation { state.keys = keys }
            } catch {
                dialogService.showToastMessage(error.localizedDescription)
            }
        }
    }
}

private extension PKGeneratorViewModel {
    func configure() {
        state.buttonDescription = getButtonDescription()
    }
    
    func getButtonDescription() -> AttributedString {
        let parser = MarkdownParser(
            font: UIFont.systemFont(ofSize: UIFont.systemFontSize),
            color: .adamant.primary
        )
        
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center
        
        let mutableText = NSMutableAttributedString(
            attributedString: parser.parse(.adamant.pkGenerator.alert)
        )
        
        mutableText.addAttribute(
            .paragraphStyle,
            value: style,
            range: .init(location: .zero, length: mutableText.length)
        )
        
        return .init(mutableText)
    }
}

private func generatePrivateKeys(
    passphrase: String,
    walletServiceCompose: WalletServiceCompose
) throws -> [PKGeneratorState.KeyInfo] {
    guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase)
    else { throw AdamantError(message: .adamant.qrGenerator.wrongPassphraseError) }
    
    return walletServiceCompose.getWallets().compactMap {
        guard
            let generator = $0.core as? PrivateKeyGenerator,
            let key = generator.generatePrivateKeyFor(passphrase: passphrase)
        else { return nil }
        
        return PKGeneratorState.KeyInfo(
            title: generator.rowTitle,
            description: .adamant.pkGenerator.keyFormat(generator.keyFormat.rawValue),
            icon: generator.rowImage ?? .init(),
            key: key
        )
    }
}
