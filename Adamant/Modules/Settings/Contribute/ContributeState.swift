//
//  ContributeState.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

struct ContributeState {
    var isCrashlyticsOn: Bool
    var isCrashButtonOn: Bool
    var safariURL: IDWrapper<URL>?
    
    let name: String
    let crashliticsRowImage: UIImage
    let crashliticsRowName: String
    let crashliticsRowDescription: String
    let crashButtonTitle: String
    let linkRows: [LinkRow]
    
    static var initial: ContributeState {
        Self(
            isCrashlyticsOn: false,
            isCrashButtonOn: false,
            name: .localized("AccountTab.Row.Contribute", comment: .empty),
            crashliticsRowImage: .asset(named: "row_crashlytics") ?? .init(),
            crashliticsRowName: .localized("Contribute.Section.Crashlytics", comment: .empty),
            crashliticsRowDescription: .localized("Contribute.Section.CrashlyticsDescription", comment: .empty),
            crashButtonTitle: "Simulate crash",
            linkRows: [
                .init(
                    image: .asset(named: "row_contribute_node") ?? .init(),
                    name: .localized("Contribute.Section.RunNodes", comment: .empty),
                    description: .localized("Contribute.Section.RunNodesDescription", comment: .empty),
                    link: URL(string: "https://news.adamant.im/how-to-run-your-adamant-node-on-ubuntu-990e391e8fcc")
                ),
                .init(
                    image: .asset(named: "row_delegate") ?? .init(),
                    name: .localized("Contribute.Section.NetworkDelegate", comment: .empty),
                    description: .localized("Contribute.Section.NetworkDelegateDescription", comment: .empty),
                    link: URL(string: "https://news.adamant.im/how-to-become-an-adamant-delegate-745f01d032f")
                ),
                .init(
                    image: .asset(named: "row_contribute_to_code") ?? .init(),
                    name: .localized("Contribute.Section.CodeContribute", comment: .empty),
                    description: .localized("Contribute.Section.CodeContributeDescription", comment: .empty),
                    link: URL(string: "https://github.com/Adamant-im")
                ),
                .init(
                    image: .asset(named: "row_donate") ?? .init(),
                    name: .localized("Contribute.Section.Donate", comment: .empty),
                    description: .localized("Contribute.Section.DonateDescription", comment: .empty),
                    link: URL(string: "https://adamant.im/donate")
                ),
                .init(
                    image: .asset(named: "row_rate") ?? .init(),
                    name: .localized("Contribute.Section.Rate", comment: .empty),
                    description: .localized("Contribute.Section.RateDescription", comment: .empty),
                    link: URL(string: "https://itunes.apple.com/app/id1341473829?action=write-review")
                )
            ]
        )
    }
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
