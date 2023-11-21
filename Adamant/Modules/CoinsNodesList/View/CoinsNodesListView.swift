//
//  CoinsNodesListView.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

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
            Button(String.adamant.coinsNodesList.reset) { viewModel.reset() }
        }
        .navigationTitle(String.adamant.coinsNodesList.title)
    }
    
    init(viewModel: CoinsNodesListViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
}

private extension CoinsNodesListView {
    func makeSection(_ model: CoinsNodesListState.Section) -> some View {
        Section(
            header: Text(model.title),
            content: {
                ForEach(model.rows) { row in
                    Row(
                        model: row,
                        setIsEnabled: { viewModel.setIsEnabled(id: row.id, value: $0) }
                    ).listRowBackground(Color(uiColor: .adamant.cellColor))
                }
            }
        )
    }
    
    func makeFastestNodeModeSection() -> some View {
        Section(
            content: {
                Toggle(
                    String.adamant.coinsNodesList.preferTheFastestNode,
                    isOn: $viewModel.state.fastestNodeMode
                ).listRowBackground(Color(uiColor: .adamant.cellColor))
            },
            footer: { Text(String.adamant.coinsNodesList.fastestNodeTip) }
        )
    }
    
    func makeResetSection() -> some View {
        Section {
            Button(action: showResetAlert) {
                Text(String.adamant.coinsNodesList.reset)
                    .expanded(axes: .horizontal)
            }.listRowBackground(Color(uiColor: .adamant.cellColor))
        }
    }
    
    func showResetAlert() {
        viewModel.state.isAlertShown = true
    }
}
