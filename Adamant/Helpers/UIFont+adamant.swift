//
//  UIFont+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension UIFont {
    static func adamantPrimary(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Exo 2", size: size)  ?? .systemFont(ofSize: size)
    }
    
    static func adamantMono(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return .monospacedSystemFont(ofSize: size, weight: weight)
    }
    
    static func adamantPrimary(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let name: String
        
        switch weight {
        case UIFont.Weight.bold:
            name = "Exo 2 Bold"
            
        case UIFont.Weight.medium:
            name = "Exo 2 Medium"
            
        case UIFont.Weight.thin:
            name = "Exo 2 Thin"
            
        case UIFont.Weight.light:
            name = "Exo 2 Light"
            
        default:
            name = "Exo 2"
        }
        
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }
    
    static var adamantChatFileRawDefault = UIFont.systemFont(ofSize: 8)
    static var adamantChatDefault = UIFont.systemFont(ofSize: 17)
    static var adamantCodeDefault = UIFont.adamantMono(ofSize: 15, weight: .regular)
    static var adamantChatReplyDefault = UIFont.systemFont(ofSize: 14)
}
