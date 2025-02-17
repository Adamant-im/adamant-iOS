import Foundation
import AdamantWalletsKit

public extension AdamantResources {
    // MARK: Nodes
    static var nodes: [Node] {
        guard
            let admWallet = CoinInfoProvider.coins["ADM"],
            let walletNodes = admWallet.nodes?.toNodes()
        else {
            print("Error: Unable to fetch wallet nodes for ADM.")
            return []
        }
        return walletNodes
    }
}
extension CoinInfoDTO.Nodes {
    func toNodes() -> [Node] {
        return list.map { walletNode in
            Node.makeDefaultNode(
                url: URL(string: walletNode.url)!,
                altUrl: walletNode.altIP.flatMap { URL(string: $0) }
            )
        }
    }
}
