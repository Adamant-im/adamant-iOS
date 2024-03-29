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
                    footer: { Text(verbatim: storageDescription) }
                )
                
                Section(
                    content: {
                        previewContent
                            .listRowBackground(Color(uiColor: .adamant.cellColor))
                    },
                    footer: { Text(verbatim: previewDescription) }
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle(storageTitle)
            
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
            Image(uiImage: storageImage)
            Text(verbatim: storageTitle)
            Spacer()
            if let storage = viewModel.storageUsedDescription {
                Text(storage)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
    
    var previewContent: some View {
        Toggle(isOn: $viewModel.autoDownloadPreview) {
            HStack {
                Image(uiImage: previewImage)
                Text(previewTitle)
            }
            .onLongPressGesture {
                viewModel.togglePreviewContent()
            }
        }
        .tint(.init(uiColor: .adamant.active))
    }
}

private let storageImage: UIImage = .asset(named: "row_storage")!
private let storageDescription: String = .localized("StorageUsage.Description")
private let storageTitle: String = .localized("StorageUsage.Title")
private let clearTitle: String = .localized("StorageUsage.Clear.Title")
private let previewImage: UIImage = .asset(named: "row_preview")!
private let previewTitle: String = .localized("Storage.AutoDownloadPreview.Title")
private let previewDescription: String = .localized("Storage.AutoDownloadPreview.Description")
