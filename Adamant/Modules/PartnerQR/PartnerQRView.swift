//
//  PartnerQRView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import UIKit

struct PartnerQRView: View {
    let screenFactory: ScreensFactory
    @ObservedObject var viewModel: PartnerQRViewModel
    
    var body: some View {
        GeometryReader { geometry in
            Form {
                infoSection()
                toggleSection()
                buttonSection()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    toolbar(maxWidth: geometry.size.width)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.presentBuyAndSell) {
            buyAndSellView()
        }
    }
    
    init(viewModel: @escaping () -> PartnerQRViewModel, screenFactory: ScreensFactory) {
        _viewModel = .init(wrappedValue: viewModel())
        self.screenFactory = screenFactory
        
        print("initPQR")
    }
}

private extension PartnerQRView {
    func toolbar(maxWidth: CGFloat) -> some View {
        Button(action: viewModel.renameContact) {
            HStack {
                if let uiImage = viewModel.partnerImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(squareSize: viewModel.partnerImageSize)
                }
                Text(viewModel.partnerName)
                    .font(.headline)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: maxWidth - toolbarSpace, alignment: .center)
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
    func buyAndSellView() -> some View {
        NavigationView {
            BuyAndSellControllerWrapper(adamantScreenFactory: screenFactory)
                .navigationBarTitle(AdmWalletViewController.Rows.buyTokens.localized, displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            viewModel.presentBuyAndSell = false
                        }, label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                        })
                    }
                }
        }
    }
}

private let toolbarSpace: CGFloat = 150

struct BuyAndSellControllerWrapper: UIViewControllerRepresentable {
    let adamantScreenFactory: ScreensFactory
    
    func makeUIViewController(context: Context) -> UIViewController {
        return adamantScreenFactory.makeBuyAndSell()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
