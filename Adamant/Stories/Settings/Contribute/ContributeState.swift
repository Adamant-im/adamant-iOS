//
//  ContributeState.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct ContributeState {
    var isCrashlyticsOn: Bool
    var isCrashButtonOn: Bool
    var safariURL: IdentifiableContainer<URL>?
    
    let name: String
    let crashliticsRowImage: UIImage
    let crashliticsRowName: String
    let crashliticsRowDescription: String
    let crashButtonTitle: String
    let linkRows: [LinkRow]
    
    static let initial = Self(
        isCrashlyticsOn: false,
        isCrashButtonOn: false,
        name: NSLocalizedString(key: "AccountTab.Row.Contribute"),
        crashliticsRowImage: UIImage(imageLiteralResourceName: "row_crashlytics"),
        crashliticsRowName: NSLocalizedString(key: "Contribute.Section.Crashlytics"),
        crashliticsRowDescription: NSLocalizedString(key: "Contribute.Section.CrashlyticsDescription"),
        crashButtonTitle: NSLocalizedString(key: "Contribute.Section.SimulateCrash"),
        linkRows: [
            .init(
                image: UIImage(imageLiteralResourceName: "row_nodes"),
                name: NSLocalizedString(key: "Contribute.Section.RunNodes"),
                description: NSLocalizedString(key: "Contribute.Section.RunNodesDescription"),
                link: URL(string: "https://news.adamant.im/how-to-run-your-adamant-node-on-ubuntu-990e391e8fcc")
            ),
            .init(
                image: UIImage(imageLiteralResourceName: "row_vote-delegates"),
                name: NSLocalizedString(key: "Contribute.Section.NetworkDelegate"),
                description: NSLocalizedString(key: "Contribute.Section.NetworkDelegateDescription"),
                link: URL(string: "https://news.adamant.im/how-to-become-an-adamant-delegate-745f01d032f")
            ),
            .init(
                image: UIImage(imageLiteralResourceName: "row_github"),
                name: NSLocalizedString(key: "Contribute.Section.CodeContribute"),
                description: NSLocalizedString(key: "Contribute.Section.CodeContributeDescription"),
                link: URL(string: "https://github.com/Adamant-im")
            ),
            .init(
                image: UIImage(imageLiteralResourceName: "row_buy-coins"),
                name: NSLocalizedString(key: "Contribute.Section.Donate"),
                description: NSLocalizedString(key: "Contribute.Section.DonateDescription"),
                link: URL(string: "https://adamant.im/donate")
            ),
        ]
    )
}

extension ContributeState {
    struct LinkRow: Identifiable {
        let id = UUID()
        let image: UIImage
        let name: String
        let description: String
        let link: URL?
    }
}
