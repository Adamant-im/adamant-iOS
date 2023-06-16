//
//  ContributeView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct ContributeView: View {
    @SwiftUI.State private var isCrashlyticsOn = false
    @SwiftUI.State private var url: IdentifiableURL?
    @StateObject private var viewModel: ContributeViewModel
    
    var body: some View {
        List {
            Section(
                content: {
                    crashliticsContent
                        .listRowBackground(Color(uiColor: .adamant.cellColor))
                    if viewModel.state.isCrashButtonOn {
                        crashButton
                            .listRowBackground(Color(uiColor: .adamant.cellColor))
                    }
                },
                footer: { Row.crashlytics.description }
            )
            makeLinkSection(row: .runNodes)
            makeLinkSection(row: .networkDelegate)
            makeLinkSection(row: .codeContribute)
            makeLinkSection(row: .donate)
        }
        .listStyle(.insetGrouped)
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle(viewModel.state.name)
        .onChange(of: isCrashlyticsOn) {
            viewModel.setIsOn($0)
        }
        .onReceive(viewModel.$state.map(\.isCrashlyticsOn).removeDuplicates()) {
            isCrashlyticsOn = $0
        }
        .fullScreenCover(item: $url) {
            SafariWebView(url: $0.url).ignoresSafeArea()
        }
    }
    
    init(viewModel: ContributeViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
}

private extension ContributeView {
    enum Row {
        case crashlytics
        case runNodes
        case networkDelegate
        case codeContribute
        case donate
        
        var image: Image {
            switch self {
            case .crashlytics:
                return Image("row_crashlytics")
            case .runNodes:
                return Image("row_nodes")
            case .networkDelegate:
                return Image("row_vote-delegates")
            case .codeContribute:
                return Image("row_github")
            case .donate:
                return Image("row_buy-coins")
            }
        }

        var name: Text {
            switch self {
            case .crashlytics:
                return Text("Contribute.Section.Crashlytics")
            case .runNodes:
                return Text("Contribute.Section.RunNodes")
            case .networkDelegate:
                return Text("Contribute.Section.NetworkDelegate")
            case .codeContribute:
                return Text("Contribute.Section.CodeContribute")
            case .donate:
                return Text("Contribute.Section.Donate")
            }
        }
        
        var description: Text {
            switch self {
            case .crashlytics:
                return Text("Contribute.Section.CrashlyticsDescription")
            case .runNodes:
                return Text("Contribute.Section.RunNodesDescription")
            case .networkDelegate:
                return Text("Contribute.Section.NetworkDelegateDescription")
            case .codeContribute:
                return Text("Contribute.Section.CodeContributeDescription")
            case .donate:
                return Text("Contribute.Section.DonateDescription")
            }
        }
        
        var url: URL? {
            switch self {
            case .crashlytics:
                return nil
            case .runNodes:
                return URL(string: "https://news.adamant.im/how-to-run-your-adamant-node-on-ubuntu-990e391e8fcc")
            case .networkDelegate:
                return URL(string: "https://news.adamant.im/how-to-become-an-adamant-delegate-745f01d032f")
            case .codeContribute:
                return URL(string: "https://github.com/Adamant-im")
            case .donate:
                return URL(string: "https://adamant.im/donate")
            }
        }
    }
    
    var crashliticsContent: some View {
        Toggle(isOn: $isCrashlyticsOn) {
            HStack {
                Row.crashlytics.image
                Row.crashlytics.name
            }
            .onLongPressGesture {
                viewModel.enableCrashButton()
            }
        }
        .tint(.init(uiColor: .adamant.active))
    }
    
    var crashButton: some View {
        Button("Simulate crash") { viewModel.simulateCrash() }
    }
    
    func makeLinkSection(row: Row) -> some View {
        Section(
            content: {
                Button(action: { openURL(row: row) }) {
                    HStack {
                        row.image
                        row.name
                        Spacer()
                        NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
                    }
                }.listRowBackground(Color(uiColor: .adamant.cellColor))
            },
            footer: { row.description }
        )
    }
    
    func openURL(row: Row) {
        url = row.url.map { .init(url: $0) }
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    
    var id: String { url.absoluteString }
}
