//
//  NavigationButton.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

public struct NavigationButton<Content: View>: View {
    private let action: () -> Void
    private let content: () -> Content
    
    public var body: some View {
        Button(action: action) {
            HStack {
                content()
                    .expanded(axes: .horizontal, alignment: .leading)
                    .contentShape(Rectangle())
                NavigationLink(destination: { EmptyView() }, label: { EmptyView() }).fixedSize()
            }
        }.buttonStyle(.plain)
    }
    
    public init(action: @escaping () -> Void, content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
}
