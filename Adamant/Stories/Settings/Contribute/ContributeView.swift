//
//  ContributeView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct ContributeView: View {
    
    // MARK: Rows
    enum Rows {
        case crashlytics
        
        var image: Image {
            switch self {
            case .crashlytics: return Image("row_crashlytics")
            }
        }
        
        var localized: Text {
            switch self {
            case .crashlytics: return Text("Contribute.Section.Crashlytics")
            }
        }
        
    }
    
    @SwiftUI.State var isOn = false
    @StateObject private var viewModel: ContributeViewModel
    
    var body: some View {
        VStack {
            Toggle(isOn: $isOn) {
                HStack {
                    Rows.crashlytics.image
                        .tint(Color(.adamant.tableRowIcons))
                    Rows.crashlytics.localized
                }
            }
            .tint(Color(.adamant.active))
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .onChange(of: isOn) {
                viewModel.setIsOn($0)
            }
            .onReceive(viewModel.$state.removeDuplicates()) { state in
                self.isOn = state.isOn
            }
            .background(Color(.adamant.cellColor))
            Spacer()
        }
        .padding(.top)
        .background(Color(.adamant.secondBackgroundColor))
        .navigationTitle(Text(viewModel.state.name))
    }
    
    init(viewModel: ContributeViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
}
