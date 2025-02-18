//
//  AdamantBalanceFormat.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Formatters

/// - full: 8 digits after the decimal point
/// - compact: 4 digits after the decimal point
/// - short: 2 digits after the decimal point
public enum AdamantBalanceFormat {
    // MARK: Styles
    /// 8 digits after the decimal point
    case full
    
    /// 4 digits after the decimal point
    case compact
    
    /// 2 digits after the decimal point
    case short
    
    /// N digits after the decimal point
    case custom(Int)
    
    // MARK: Formatters
    
    public static func currencyFormatter(for format: AdamantBalanceFormat, currencySymbol symbol: String?) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .floor
        formatter.minimumFractionDigits = 0
        
        var positiveFormat: String
        
        switch format {
        case .full: positiveFormat = "#.########"
        case .compact:
            formatter.roundingMode = .ceiling
            positiveFormat = "#.####"
        case .short: positiveFormat = "#.##"
        case .custom(let digits):
            positiveFormat = "#."
            for _ in 1...digits  {
                positiveFormat.append("#")
            }
        }
        
        if let symbol = symbol {
            formatter.positiveFormat = "\(positiveFormat) \(symbol)"
        } else {
            formatter.positiveFormat = positiveFormat
        }
        
        return formatter
    }
    
    public static let currencyFormatterFull = currencyFormatter(for: .full, currencySymbol: nil)
    public static let currencyFormatterCompact = currencyFormatter(for: .compact, currencySymbol: nil)
    public static let currencyFormatterShort = currencyFormatter(for: .short, currencySymbol: nil)
    
    // MARK: Methods
    
    public var defaultFormatter: NumberFormatter {
        switch self {
        case .full: return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: nil)
        case .compact: return AdamantBalanceFormat.currencyFormatter(for: .compact, currencySymbol: nil)
        case .short: return AdamantBalanceFormat.currencyFormatter(for: .short, currencySymbol: nil)
        case .custom(let decimals): return AdamantBalanceFormat.currencyFormatter(for: .custom(decimals), currencySymbol: nil)
        }
    }
    
    public func format(_ value: Decimal, withCurrencySymbol symbol: String? = nil) -> String {
        if let symbol = symbol {
            return "\(defaultFormatter.string(from: value)!) \(symbol)"
        } else {
            return defaultFormatter.string(from: value)!
        }
    }
    
    public func format(_ value: Double, withCurrencySymbol symbol: String? = nil) -> String {
        if let symbol = symbol {
            return "\(defaultFormatter.string(from: NSNumber(floatLiteral: value))!) \(symbol)"
        } else {
            return defaultFormatter.string(from: NSNumber(floatLiteral: value))!
        }
    }
    
    // MARK: Other formatters
    
    public static let rawNumberDotFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.roundingMode = .floor
        f.decimalSeparator = "."
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 12 // 18 is too low, 0.007 for example will serialize as 0.007000000000000001
        return f
    }()
    
    public static let rawNumberCommaFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.roundingMode = .floor
        f.decimalSeparator = ","
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 12 // 18 is too low, 0.007 for example will serialize as 0.007000000000000001
        return f
    }()
    
    public static func deserializeBalance(from string: String) -> Decimal? {
        // NumberFormatter.number(from: string).decimalValue loses precision.
        
        if let number = Decimal(string: string), number != 0.0 {
            return number
        } else if let number = Decimal(string: string, locale: Locale.current), number != 0.0 {
            return number
        } else if let number = AdamantBalanceFormat.rawNumberDotFormatter.number(from: string) {
            return number.decimalValue
        } else if let number = AdamantBalanceFormat.rawNumberCommaFormatter.number(from: string) {
            return number.decimalValue
        } else {
            return nil
        }
    }
}

// MARK: - Helper
public extension NumberFormatter {
    func string(from decimal: Decimal) -> String? {
        return string(from: NSNumber(value: decimal.doubleValue))
    }
}
