//
//  StorageUsageView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit
import Charts

struct StorageUsageView: View {
    @StateObject private var viewModel: StorageUsageViewModel
    
    init(viewModel: StorageUsageViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                Section(
                    content: {
                        content
                            .listRowBackground(Color(uiColor: .adamant.cellColor))
                    },
                    footer: { Text(verbatim: description) }
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            
            Spacer()
            
            HStack {
                Button {
                    viewModel.clearStorage()
                } label: {
                    Text(clearTitle)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(uiColor: UIColor.adamant.active))
                .clipShape(.rect(cornerRadius: 8.0))
                .padding()
            }
        }
        .onAppear(perform: {
            viewModel.updateCacheSize()
        })
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
    }
}

private extension StorageUsageView {
    var content: some View {
        HStack {
            Image(uiImage: image)
            Text(verbatim: title)
            Spacer()
            if let storage = viewModel.storageUsedDescription {
                Text(storage)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
}

private let image: UIImage = .asset(named: "row_storage")!
private let description: String = .localized("StorageUsage.Description")
private let title: String = .localized("StorageUsage.Title")
private let clearTitle: String = .localized("StorageUsage.Clear.Title")
