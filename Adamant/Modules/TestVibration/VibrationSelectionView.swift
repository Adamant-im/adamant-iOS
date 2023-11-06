//
//  VibrationSelectionView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

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
    }
    
    private func vibrationTypeDescription(_ type: AdamantVibroType) -> String {
        switch type {
        case .light:
            return "Light Vibration"
        case .rigid:
            return "Rigid Vibration"
        case .heavy:
            return "Heavy Vibration"
        case .medium:
            return "Medium Vibration"
        case .soft:
            return "Soft Vibration"
        case .selection:
            return "Selection Vibration"
        case .success:
            return "Success Vibration"
        case .warning:
            return "Warning Vibration"
        case .error:
            return "Error Vibration"
        }
    }
}
