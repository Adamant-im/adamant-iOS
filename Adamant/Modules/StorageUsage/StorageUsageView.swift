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
                        autoDownloadContent(for: .preview)
                            .listRowBackground(Color(uiColor: .adamant.cellColor))
                        autoDownloadContent(for: .fullMedia)
                            .listRowBackground(Color(uiColor: .adamant.cellColor))
                    },
                    header: { Text(verbatim: autDownloadHeader) },
                    footer: { Text(verbatim: autDownloadDescription) }
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
            viewModel.loadData()
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
    
    func autoDownloadContent(
        for type: StorageUsageViewModel.AutoDownloadMediaType
    ) -> some View {
        Button {
            viewModel.presentPicker(for: type)
        } label: {
            HStack {
                Image(uiImage: previewImage)
                Text(type.title)
                
                Spacer()
                
                switch type {
                case .preview:
                    Text(viewModel.autoDownloadPreview.title)
                case .fullMedia:
                    Text(viewModel.autoDownloadFullMedia.title)
                }
                
                NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
            }
        }
    }
}

private let storageImage: UIImage = .asset(named: "row_storage")!
private var storageDescription: String { .localized("StorageUsage.Description") }
private var storageTitle: String { .localized("StorageUsage.Title") }
private var clearTitle: String { .localized("StorageUsage.Clear.Title") }
private let previewImage: UIImage = .asset(named: "row_preview")!
private var autDownloadHeader: String { .localized("Storage.AutoDownloadPreview.Header") }
private var autDownloadDescription: String { .localized("Storage.AutoDownloadPreview.Description") }
