import AdamantWalletsKit
import Foundation

extension AdamantResources {
    // MARK: Nodes
    public static var nodes: [Node] {
        guard
            let admWallet = CoinInfoProvider.storage?["ADM"],
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
        list.map { walletNode in
            Node.makeDefaultNode(
                url: URL(string: walletNode.url)!,
                altUrl: walletNode.altIP.flatMap { URL(string: $0) }
            )
        }
    }
}
