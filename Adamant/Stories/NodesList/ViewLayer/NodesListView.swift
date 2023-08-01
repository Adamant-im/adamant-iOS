//
//  NodesListView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 01.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

struct NodesListView: View {
    @StateObject private var viewModel: NodesListViewModel
    
    var body: some View {
        List {
            ForEach($viewModel.state.sections, id: \.self) { $section in
                Section(section.name) {
                    ForEach($section.nodes, id: \.self) { $node in
                        makeNodeRow($node)
                    }.listRowBackground(Color(uiColor: .adamant.cellColor))
                }
            }
            
            Section { resetButton.listRowBackground(Color(uiColor: .adamant.cellColor)) }
        }
        .navigationTitle(String.adamant.nodesList.title)
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
    }
    
    init(viewModel: NodesListViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
}

private extension NodesListView {
    var resetButton: some View {
        Button(action: { viewModel.reset() }) {
            Text(String.adamant.nodesList.resetAlertTitle)
                .expanded(axes: .horizontal)
        }
    }
    
    func makeNodeRow(_ node: Binding<NodesListViewState.NodesSection.Node>) -> some View {
        CheckmarkRowView(
            isChecked: node.isEnabled,
            title: node.wrappedValue.address,
            subtitle: node.wrappedValue.ping,
            caption: "●",
            checkmarkImage: .asset(named: "status_success"),
            captionColor: node.wrappedValue.status.color
        )
    }
}

private extension NodesListViewState.NodesSection.Node.Status {
    var color: UIColor {
        switch self {
        case .allowed:
            return .adamant.good
        case .synchronizing:
            return .adamant.alert
        case .offline:
            return .adamant.danger
        case .default:
            return .adamant.inactive
        }
    }
}
