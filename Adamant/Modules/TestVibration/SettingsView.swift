//
//  SettingsView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import SwiftUI

struct SettingsView: View {
    enum SettingsType: String, CaseIterable {
        case adamantWallets = "Adamant-Wallets"
    }

    @StateObject var viewModel: VibrationSelectionViewModel
    private let onSettingsSelect: (SettingsType) -> Void

    init(viewModel: @escaping () -> VibrationSelectionViewModel, onSettingsSelect: @escaping (SettingsType) -> Void) {
        _viewModel = .init(wrappedValue: viewModel())
        self.onSettingsSelect = onSettingsSelect
    }

    var body: some View {
        List {
            Section("Vibrations") {
                ForEach(AdamantVibroType.allCases, id: \.self) { type in
                    Button {
                        viewModel.type = type
                    } label: {
                        Text(vibrationTypeDescription(type))
                    }
                }
            }
            Section("Adamant-Wallets") {
                ForEach(SettingsType.allCases, id: \.rawValue) { type in
                    Button {
                        onSettingsSelect(type)
                    } label: {
                        Text(type.rawValue)
                    }
                }
            }
        }
        .withoutListBackground()
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle("Preferrences")
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
