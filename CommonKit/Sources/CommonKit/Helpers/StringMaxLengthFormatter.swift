//
//  StringMaxLengthFormatter.swift
//
//
//  Created by Stanislav Jelezoglo on 12.07.2024.
//

import Foundation

public class StringMaxLengthFormatter: Formatter {
    private let maxLength: Int

    public init(maxLength: Int) {
        self.maxLength = maxLength
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func string(for obj: Any?) -> String? {
        guard let string = obj as? String else {
            return nil
        }
        
        return String(string.prefix(maxLength))
    }

    public override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        if let obj = obj {
            obj.pointee = self.string(for: string) as AnyObject?
        }
    
        return true
    }
}
