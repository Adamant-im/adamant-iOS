//
//  VibrationSelectionView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

struct VibrationSelectionView: View {
    @StateObject var viewModel: VibrationSelectionViewModel
    
    init(viewModel: VibrationSelectionViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            ForEach(AdamantVibroType.allCases, id: \.self) { type in
                Button {
                    viewModel.type = type
                } label: {
                    Text(vibrationTypeDescription(type))
                }
            }
        }
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle("Vibrations")
    }
    
    private func vibrationTypeDescription(_ type: AdamantVibroType) -> String {
        switch type {
        case .light:
            return "Single-Short-Light (1SL Vibartion)"
        case .rigid:
            return "Single-Short-Rigid (1SR Vibartion)"
        case .heavy:
            return "Single-Long-Rigid (1LR Vibartion)"
        case .medium:
            return "Single-Short-Medium (1SM Vibartion)"
        case .soft:
            return "Single-Long-Soft (1LS Vibartion)"
        case .selection:
            return "Single-Short-Soft (1SS Vibartion)"
        case .success:
            return "Double-Short-Medium (2SM Vibartion)"
        case .warning:
            return "Double-Long-Medium (2LM Vibartion)"
        case .error:
            return "Tripple-Long-Medium (3LM Vibartion)"
        }
    }
}
