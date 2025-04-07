//
//  String+utilites.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension String {
    public static let empty: String = ""

    public func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    public func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))

            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    public func checkAndReplaceSystemWallets() -> String {
        AdamantContacts(nodeNameKey: self)?.name
            ?? AdamantContacts(address: self)?.name
            ?? self
    }

    public subscript(i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }

    public func separateFileExtension() -> (name: String, extension: String?) {
        guard let dotIndex = lastIndex(of: ".") else {
            return (name: self, extension: nil)
        }

        return (
            name: .init(self[startIndex..<dotIndex]),
            extension: .init(self[dotIndex..<endIndex].dropFirst())
        )
    }

    public func withoutFileExtensionDuplication() -> String {
        let dotsCount = count { $0 == "." }
        guard dotsCount > 1 else { return self }

        var nameAndExtension = separateFileExtension()
        var filename = nameAndExtension.name
        guard let ext = nameAndExtension.extension else { return self }

        for _ in 1..<dotsCount {
            nameAndExtension = filename.separateFileExtension()
            guard nameAndExtension.extension == ext else { return "\(filename).\(ext)" }
            filename = nameAndExtension.name
        }

        return "\(filename).\(ext)"
    }
}
