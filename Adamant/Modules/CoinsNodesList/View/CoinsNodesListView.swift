//
//  CoinsNodesListView.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import SwiftUI

struct CoinsNodesListView: View {
    @StateObject private var viewModel: CoinsNodesListViewModel

    var body: some View {
        List {
            ForEach(viewModel.state.sections, content: makeSection)
            makeFastestNodeModeSection()
            makeResetSection()
        }
        .listStyle(.insetGrouped)
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .alert(
            String.adamant.coinsNodesList.resetAlert,
            isPresented: $viewModel.state.isAlertShown
        ) {
            Button(String.adamant.alert.cancel, role: .cancel) {}
            Button(String.adamant.coinsNodesList.reset, role: .destructive) { viewModel.reset() }
        }
        .navigationTitle(String.adamant.coinsNodesList.title)
    }

    init(viewModel: @escaping () -> CoinsNodesListViewModel) {
        _viewModel = .init(wrappedValue: viewModel())
    }
}

extension CoinsNodesListView {
    fileprivate func makeSection(_ model: CoinsNodesListState.Section) -> some View {
        Section(
            header: Text(model.title),
            content: {
                ForEach(model.rows) { row in
                    Row(
                        model: row,
                        setIsEnabled: {
                            viewModel.setIsEnabled(
                                id: row.id,
                                group: row.group,
                                value: $0
                            )
                        }
                    ).listRowBackground(Color(uiColor: .adamant.cellColor))
                }
            }
        )
    }

    fileprivate func makeFastestNodeModeSection() -> some View {
        Section(
            content: {
                Toggle(
                    String.adamant.coinsNodesList.preferTheFastestNode,
                    isOn: $viewModel.state.fastestNodeMode
                )
                .listRowBackground(Color(uiColor: .adamant.cellColor))
                .tint(Color(uiColor: .adamant.active))
            },
            footer: { Text(String.adamant.coinsNodesList.fastestNodeTip) }
        )
    }

    fileprivate func makeResetSection() -> some View {
        Section {
            Button(action: showResetAlert) {
                Text(String.adamant.coinsNodesList.reset)
                    .foregroundStyle(Color(uiColor: .adamant.textColor))
                    .expanded(axes: .horizontal)
            }.listRowBackground(Color(uiColor: .adamant.cellColor))
        }
    }

    fileprivate func showResetAlert() {
        viewModel.state.isAlertShown = true
    }
}
