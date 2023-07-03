//
//  MenuView.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

struct MenuView: View {
    let menu: UIMenu
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(menu.children, id: \.title) { item in
                Button {
                    print("action")
                } label: {
                    HStack {
                        Text(item.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .tint(.black)
                            .foregroundColor(.black)
                        if let image = item.image {
                            Image(uiImage: image)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 10)
                                .tint(.black)
                        }
                    }
                }

                if menu.children.last != item {
                    Divider()
                }
            }
        }
        .padding(10)
        .background(Blur(style: .light, sensetivity: 1.0))
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(maxWidth: 250)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.red : Color.clear)
    }
}
