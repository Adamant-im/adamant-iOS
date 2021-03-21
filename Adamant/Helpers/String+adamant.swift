//
//  String+adamant.swift
//  Adamant
//
//  Created by Anton Boyarkin on 22/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

struct AdamantAddress {
    let address: String
    let name: String?
}

extension String {
    func getAdamantAddress() -> AdamantAddress? {
        let address: String?
        var name: String? = nil
        
        if let uri = AdamantUriTools.decode(uri: self) {
            switch uri {
            case .address(address: let addr, params: let params):
                address = addr
                
                if let params = params {
                    for param in params {
                        switch param {
                        case .label(let label):
                            name = label
                            break
                        }
                    }
                }
                
            case .passphrase(_):
                address = nil
            }
        } else {
            switch AdamantUtilities.validateAdamantAddress(address: self) {
            case .valid, .system:
                address = self
                
            case .invalid:
                address = nil
            }
        }
        
        if let address = address {
            return AdamantAddress(address: address, name: name)
        } else {
            return nil
        }
    }
    
}

public extension NSMutableAttributedString {

    func apply(font: UIFont, alignment: NSTextAlignment) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let stringRange = NSRange(location: 0, length: self.length)
        self.setBaseFont(baseFont: font)
        self.addAttributes([.paragraphStyle: paragraphStyle], range: stringRange)
    }
    
    /// Replaces the base font with the given font while preserving traits like bold and italic
    func setBaseFont(baseFont: UIFont) {
        let baseDescriptor = baseFont.fontDescriptor
        let wholeRange = NSRange(location: 0, length: length)
        beginEditing()
        enumerateAttribute(.font, in: wholeRange, options: []) { object, range, _ in
            guard let font = object as? UIFont else { return }
            let traits = font.fontDescriptor.symbolicTraits
            guard let descriptor = baseDescriptor.withSymbolicTraits(traits) else { return }
            let newFont = UIFont(descriptor: descriptor, size: baseDescriptor.pointSize)
            self.removeAttribute(.font, range: range)
            self.addAttribute(.font, value: newFont, range: range)
        }
        endEditing()
    }

}
