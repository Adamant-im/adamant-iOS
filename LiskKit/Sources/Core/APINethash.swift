//
//  APINethash.swift
//  Lisk
//
//  Created by Andrew Barba on 12/26/17.
//

import Foundation

/// Nethash options that are sent as request headers
public struct APINethash {

    /// Nethash
    public let nethash: String

    /// Current api version
    public let version: String

    /// Minmimum supported api version
    public let minVersion = ">=1.0.0"

    /// HTTP content type
    public let contentType = "application/json"

    // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
    // Example: `iOS Example/1.0 (org.alamofire.iOS-Example; build:1; iOS 10.0.0) Alamofire/4.0.0`
    // Source: https://github.com/Alamofire/Alamofire/blob/7bef9405f1d589605f253147b8e6939261b0867c/Source/SessionManager.swift#L68
    public let userAgent: String = {
        let liskSwiftVersion = "LiskSwift/\(Constants.version)"

        guard let info = Bundle.main.infoDictionary else {
            return liskSwiftVersion
        }

        let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
        let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
        let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

        let osNameVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

            let osName: String = {
                #if os(iOS)
                return "iOS"
                #elseif os(watchOS)
                return "watchOS"
                #elseif os(tvOS)
                return "tvOS"
                #elseif os(macOS)
                return "OS X"
                #elseif os(Linux)
                return "Linux"
                #else
                return "Unknown"
                #endif
            }()

            return "\(osName) \(versionString)"
        }()

        return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion)) \(liskSwiftVersion)"
    }()

    private init(nethash: String, version: String) {
        self.nethash = nethash
        self.version = version
    }
}

extension APINethash {

    /// Mainnet options
    public static let mainnet: APINethash = .init(nethash: Constants.Nethash.main, version: Constants.version)

    /// Testnet options
    public static let testnet: APINethash = .init(nethash: Constants.Nethash.test, version: Constants.version)

    /// Betanet options
    public static let betanet: APINethash = .init(nethash: Constants.Nethash.beta, version: Constants.version)
}
