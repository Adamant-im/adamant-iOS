//
//  String+adamant.swift
//  Adamant
//
//  Created by Anton Boyarkin on 22/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit

struct AdamantAddress {
    let address: String
    let name: String?
    let amount: Double?
    let message: String?
}

extension String {
    func getAdamantAddress() -> AdamantAddress? {
        guard
            let urlString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let components = URLComponents(string: urlString),
            let queryItems = components.queryItems,
            let address = queryItems.filter({$0.name == "address"}).first?.value else {
            return nil
        }
        
        let name = queryItems.filter({$0.name == "label"}).first?.value?.replacingOccurrences(of: "+", with: " ").replacingOccurrences(of: "%20", with: " ")
        let amount = queryItems.filter({$0.name == "amount"}).first?.value
        let message = queryItems.filter({$0.name == "message"}).first?.value?.replacingOccurrences(of: "+", with: " ").replacingOccurrences(of: "%20", with: " ")
        var amountDouble: Double?
        if let amount = amount {
            amountDouble = Double(amount)
        }
        return AdamantAddress(address: address, name: name, amount: amountDouble, message: message)
    }

    func getLegacyAdamantAddress() -> AdamantAddress? {
        let address: String?
        var name: String?
        var message: String?
        
        let newUrl = self.replacingOccurrences(of: "//", with: "")
        
        if let uri = AdamantUriTools.decode(uri: newUrl) {
            switch uri {
            case .address(address: let addr, params: let params):
                address = addr
                if let params = params {
                    for param in params {
                        switch param {
                        case .address:
                            break
                        case .label(let label):
                            name = label
                        case .message(let urlMessage):
                            message = urlMessage
                        }
                    }
                }
                
            case .passphrase:
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
            return AdamantAddress(address: address, name: name, amount: nil, message: message)
        } else {
            return nil
        }
    }
    
    func validateEthAddress() -> String {
        let address = self
        let prefix = address.prefix(2)
        
        let fixedAddress = prefix != "0x"
        ? "0x\(address)"
        : address
        
        return fixedAddress
    }
}

public extension NSMutableAttributedString {

    func apply(font: UIFont, alignment: NSTextAlignment) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment

        let stringRange = NSRange(location: 0, length: self.length)
        self.setBaseFont(baseFont: font)
        self.addAttributes([.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.adamant.textColor], range: stringRange)
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
