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
                MenuButtonView(item: item)
                
                if menu.children.last != item {
                    Divider()
                }
            }
        }
        .padding([.top, .bottom], 10)
        .background(Blur(style: .light, sensetivity: 1.0))
        .cornerRadius(10)
        .shadow(radius: 5)
        .frame(maxWidth: 250)
    }
}

struct MenuButtonView: View {
    @State private var isHovered = false
    
    var item: UIMenuElement
    
    var body: some View {
        Button {
            print("\(item.title) tapped")
        } label: {
            HStack {
                Text(item.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .tint(.black)
                    .foregroundColor(.black)
                    .font(.system(size: 16))
                if let image = item.image {
                    Image(uiImage: image)
                        .font(Font.title.weight(.ultraLight))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 20)
                        .tint(.black)
                }
            }
        }
        .buttonStyle(MenuButtonStyle(isHovered: $isHovered))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onHover { hovering in
            isHovered = hovering
        }
        .frame(height: 20)
    }
}

struct MenuButtonStyle: ButtonStyle {
    @Binding var isHovered: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                Rectangle()
                    .fill(
                        configuration.isPressed
                        ? Color.gray.opacity(0.15)
                        : isHovered ? Color.gray.opacity(0.15) : Color.clear
                    )
                    .frame(height: 40)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
