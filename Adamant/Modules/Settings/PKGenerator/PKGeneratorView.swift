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
                
                Button(action: { viewModel.generateKeys() }) {
                    Text(String.adamant.pkGenerator.generateButton)
                        .foregroundStyle(Color(uiColor: .adamant.primary))
                        .padding(.horizontal, 30)
                        .background(loadingBackground)
                        .expanded(axes: .horizontal)
                }
            }.listRowBackground(Color(uiColor: .adamant.cellColor))
        }
    }
    
    func keyView(_ keyInfo: PKGeneratorState.KeyInfo) -> some View {
        NavigationButton(action: { viewModel.onTap(key: keyInfo.key) }) {
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
        }
    }
}
