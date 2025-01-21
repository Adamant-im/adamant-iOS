//
//  CoinsNodesListView+Row.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import CommonKit

extension CoinsNodesListView {
    struct Row: View {
        let model: CoinsNodesListState.Section.Row
        let setIsEnabled: (Bool) -> Void
        
        var body: some View {
            HStack(spacing: 10) {
                CheckmarkView(
                    isEnabled: model.isEnabled,
                    setIsEnabled: setIsEnabled
                )
                .frame(squareSize: 24)
                .animation(.easeInOut(duration: 0.1), value: model.isEnabled)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.title).font(titleFont).lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(model.connectionStatus).font(captionFont)
                        
                        Text(model.subtitle).font(subtitleFont)
                            .lineLimit(1)
                            .frame(height: 10)
                    }
                }
            }.padding(2)
        }
    }
}

private extension CoinsNodesListView.Row {
    struct CheckmarkView: View {
        let isEnabled: Bool
        let setIsEnabled: (Bool) -> Void
        
        var body: some View {
            ZStack {
                if isEnabled {
                    Image(uiImage: .asset(named: "status_success") ?? .strokedCheckmark)
                        .resizable()
                        .scaledToFit()
                        .transition(.scale)
                }
                
                if !isEnabled {
                    Circle().strokeBorder(
                        Color(uiColor: .adamant.secondary),
                        lineWidth: 1
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                setIsEnabled(!isEnabled)
            }
        }
    }
}

private let titleFont = Font.system(size: 17, weight: .regular)
private let subtitleFont = Font(UIFont.preferredFont(forTextStyle: .caption1))
private let captionFont = Font.system(size: 12, weight: .regular)
