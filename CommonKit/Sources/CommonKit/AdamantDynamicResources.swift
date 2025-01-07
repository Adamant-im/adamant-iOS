import Foundation
import AdamantWalletsAssets

public extension AdamantResources {
    // MARK: Nodes
    static var nodes: [Node] {
        guard
            let admWallet = WalletFactory().wallet(for: "ADM"),
            let walletNodes = admWallet.walletNodes
        else {
            print("Error: Unable to fetch wallet nodes for ADM.")
            return []
        }
        return walletNodes.toNodes()
    }
}
