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
        }
        .listStyle(.insetGrouped)
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
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
}
