//
//  NavigationButton.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct NavigationButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            HStack {
                content()
                    .expanded(axes: .horizontal, alignment: .leading)
                    .contentShape(Rectangle())
                NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
            }
        }.buttonStyle(.plain)
    }
}
