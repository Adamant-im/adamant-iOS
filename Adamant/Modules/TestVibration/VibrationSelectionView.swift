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
    
    init(viewModel: @escaping () -> VibrationSelectionViewModel) {
        _viewModel = .init(wrappedValue: viewModel())
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
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func vibrationTypeDescription(_ type: AdamantVibroType) -> String {
        switch type {
        case .light:
            return "Light (-)"
        case .rigid:
            return "Rigid (v-short)"
        case .heavy:
            return "Heavy (Strong)"
        case .medium:
            return "Medium (Medium)"
        case .soft:
            return "Soft (Short)"
        case .selection:
            return "Selection (-)"
        case .success:
            return "Success (Double-v-Short)"
        case .warning:
            return "Warning (Double-Short)"
        case .error:
            return "Error (Triple-v-Short)"
        }
    }
}
