//
//  ContributeView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import SwiftUI

struct ContributeView: View {
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
                footer: { Text(viewModel.state.crashliticsRowDescription) }
            )

            ForEach(viewModel.state.linkRows) {
                makeLinkSection(row: $0)
            }
        }
        .listStyle(.insetGrouped)
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle(viewModel.state.name)
        .fullScreenCover(item: $viewModel.state.safariURL) {
            SafariWebView(url: $0.value).ignoresSafeArea()
        }
    }

    init(viewModel: @escaping () -> ContributeViewModel) {
        _viewModel = .init(wrappedValue: viewModel())
    }
}

extension ContributeView {
    fileprivate var crashliticsContent: some View {
        Toggle(isOn: $viewModel.state.isCrashlyticsOn) {
            HStack {
                Image(uiImage: viewModel.state.crashliticsRowImage)
                Text(viewModel.state.crashliticsRowName)
            }
            .onLongPressGesture {
                viewModel.enableCrashButton()
            }
        }
        .tint(.init(uiColor: .adamant.active))
    }

    fileprivate var crashButton: some View {
        Button(viewModel.state.crashButtonTitle) { viewModel.simulateCrash() }
    }

    fileprivate func makeLinkSection(row: ContributeState.LinkRow) -> some View {
        Section(
            content: {
                NavigationButton(action: { viewModel.openLink(row: row) }) {
                    HStack {
                        Image(uiImage: row.image)
                        Text(row.name)
                    }
                }.listRowBackground(Color(uiColor: .adamant.cellColor))
            },
            footer: { Text(row.description) }
        )
    }
}
