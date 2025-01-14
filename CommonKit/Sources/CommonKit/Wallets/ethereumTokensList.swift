import Foundation
import AdamantWalletsAssets

public extension ERC20Token {
    static let supportedTokens: [ERC20Token] = ERC20TokenComparer.loadTokens()
}
