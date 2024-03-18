//
//  PartnerQRView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct PartnerQRView: View {
    @ObservedObject var viewModel: PartnerQRViewModel
    
    var body: some View {
        Form {
            infoSection()
            toggleSection() 
            buttonSection()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbar()
            }
        }
    }
}

private extension PartnerQRView {
    func toolbar() -> some View {
        HStack {
            if let uiImage = viewModel.partnerImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(squareSize: viewModel.partnerImageSize)
            }
            Text(viewModel.partnerName).font(.headline)
        }
    }
    
    func infoSection() -> some View {
        Section {
            if let uiImage = viewModel.image {
                HStack {
                    Spacer()
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 250)
                    Spacer()
                }
            }
            
            HStack {
                Spacer()
                Button(action: {
                    viewModel.copyToPasteboard()
                }, label: {
                    Text(viewModel.title)
                        .padding()
                })
                Spacer()
            }
        }
    }
    
    func toggleSection() -> some View {
        Section {
            Toggle(String.adamant.partnerQR.includePartnerName, isOn: $viewModel.includeContactsName)
                .disabled(!viewModel.includeContactsNameEnabled)
                .tint(.init(uiColor: .adamant.active))
                .onChange(of: viewModel.includeContactsName) { _ in
                    viewModel.didToggle()
                }
            
            Toggle(String.adamant.partnerQR.includePartnerURL, isOn: $viewModel.includeWebAppLink)
                .tint(.init(uiColor: .adamant.active))
                .onChange(of: viewModel.includeWebAppLink) { _ in
                    viewModel.didToggle()
                }
        }
    }
    
    func buttonSection() -> some View {
        Section {
            Button(viewModel.renameTitle) {
                viewModel.renameContact()
            }
            
            Button(String.adamant.alert.saveToPhotolibrary) {
                viewModel.saveToPhotos()
            }
            
            Button(String.adamant.alert.share) {
                viewModel.share()
            }
        }
    }
}
