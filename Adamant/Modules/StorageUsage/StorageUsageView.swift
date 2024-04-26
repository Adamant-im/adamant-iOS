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
                storageSection
                autoDownloadSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(storageTitle)
            
            Spacer()
            
            makeClearButton()
        }
        .alert(
            clearPopupTitle,
            isPresented: $viewModel.isRemoveAlertShown
        ) {
            Button(String.adamant.alert.cancel, role: .cancel) {}
            Button(clearTitle) { viewModel.clearStorage() }
        }
        .onAppear(perform: {
            viewModel.loadData()
        })
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
    }
}

private extension StorageUsageView {
    var storageSection: some View {
        Section(
            content: {
                content
                    .listRowBackground(Color(uiColor: .adamant.cellColor))
            },
            footer: { Text(verbatim: storageDescription) }
        )
    }
    
    var autoDownloadSection: some View {
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
    
    var content: some View {
        HStack {
            Image(uiImage: storageImage)
            Text(verbatim: storageUsedTitle)
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
    
    func makeClearButton() -> some View {
        Button(action: showClearAlert) {
            Text(clearTitle)
                .expanded(axes: .horizontal)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 45)
        .background(Color(uiColor: .adamant.cellColor))
        .clipShape(.rect(cornerRadius: 8.0))
        .padding()
    }
    
    func showClearAlert() {
        viewModel.isRemoveAlertShown = true
    }
}

private var storageUsedTitle: String { .localized("StorageUsed.Title") }
private let storageImage: UIImage = .asset(named: "row_storage")!
private var storageDescription: String { .localized("StorageUsage.Description") }
private var storageTitle: String { .localized("StorageUsage.Title") }
private var clearPopupTitle: String { .localized("StorageUsage.Clear.Popup.Title") }
private var clearTitle: String { .localized("StorageUsage.Clear.Title") }
private let previewImage: UIImage = .asset(named: "row_preview")!
private var autDownloadHeader: String { .localized("Storage.AutoDownloadPreview.Header") }
private var autDownloadDescription: String { .localized("Storage.AutoDownloadPreview.Description") }
