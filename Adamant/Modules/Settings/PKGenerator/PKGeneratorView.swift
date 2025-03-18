//
//  PKGeneratorView.swift
//  Adamant
//
//  Created by Andrew G on 28.11.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

struct PKGeneratorView: View {
    @StateObject private var viewModel: PKGeneratorViewModel
    
    var body: some View {
        List {
            if !viewModel.state.keys.isEmpty {
                keysSection
            }
            
            inputSection
        }
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle(String.adamant.pkGenerator.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    init(viewModel: @escaping () -> PKGeneratorViewModel) {
        _viewModel = .init(wrappedValue: viewModel())
    }
}

private extension PKGeneratorView {
    private var inactiveBaseColor: Color {
        Color(UIColor.gray.withAlphaComponent(0.5))
    }
    private var activeBaseColor: Color {
        Color(UIColor.adamant.primary)
    }
    
    var loadingBackground: some View {
        HStack {
            Spacer()
            
            if viewModel.state.isLoading {
                ProgressView()
            }
        }
    }
    
    var keysSection: some View {
        Section {
            ForEach(viewModel.state.keys, content: keyView)
                .listRowBackground(Color(uiColor: .adamant.cellColor))
        }
    }
    
    var inputSection: some View {
        Section {
            Group {
                Text(viewModel.state.buttonDescription)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 5)
                
                AdamantSecureField(
                    placeholder: .adamant.qrGenerator.passphrasePlaceholder,
                    text: $viewModel.state.passphrase
                )
                
                Toggle(isOn: $viewModel.state.isSecretWalletsEnabled) {
                    Text(String.adamant.qrGenerator.toggleTitle)
                        .foregroundColor(viewModel.state.isSecretWalletsEnabled ? activeBaseColor : inactiveBaseColor)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(uiColor: .adamant.active)))
                
                if viewModel.state.isSecretWalletsEnabled {
                    AdamantSecureField(
                        placeholder: .adamant.qrGenerator.passwordPlaceholder,
                        text: $viewModel.state.secretWalletPassword
                    )
                }
                
                Button(action: { viewModel.generateKeys() }, label: {
                    Text(String.adamant.pkGenerator.generateButton)
                        .foregroundStyle(Color(uiColor: .adamant.primary))
                        .padding(.horizontal, 30)
                        .background(loadingBackground)
                        .expanded(axes: .horizontal)
                })
            }.listRowBackground(Color(uiColor: .adamant.cellColor))
        }
    }
    
    func keyView(_ keyInfo: PKGeneratorState.KeyInfo) -> some View {
        NavigationButton(action: { viewModel.onTap(key: keyInfo.key) }, content: {
            HStack {
                Image(uiImage: keyInfo.icon)
                    .renderingMode(.template)
                    .resizable()
                    .frame(squareSize: 25)
                    .foregroundStyle(Color(uiColor: .adamant.tableRowIcons))
                 
                VStack(alignment: .leading) {
                    Text(keyInfo.title)
                    Text(keyInfo.description)
                        .foregroundStyle(Color(uiColor: .adamant.secondary))
                        .font(.system(size: 12, weight: .ultraLight))
                }
                
                Spacer(minLength: .zero)
                
                Text(keyInfo.key).lineLimit(1)
                    .foregroundStyle(Color(uiColor: .adamant.secondary))
            }
        })
    }
}
