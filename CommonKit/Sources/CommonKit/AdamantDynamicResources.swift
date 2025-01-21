import Foundation

public extension AdamantResources {
    // MARK: Nodes
    static var nodes: [Node] {
        [
            Node.makeDefaultNode(url: URL(string: "https://clown.adamant.im")!),
            Node.makeDefaultNode(url: URL(string: "https://lake.adamant.im")!),
            Node.makeDefaultNode(
                url: URL(string: "https://endless.adamant.im")!,
                altUrl: URL(string: "http://149.102.157.15:36666")
            ),
            Node.makeDefaultNode(url: URL(string: "https://bid.adamant.im")!),
            Node.makeDefaultNode(url: URL(string: "https://unusual.adamant.im")!),
            Node.makeDefaultNode(
                url: URL(string: "https://debate.adamant.im")!,
                altUrl: URL(string: "http://95.216.161.113:36666")
            ),
            Node.makeDefaultNode(url: URL(string: "http://78.47.205.206:36666")!),
            Node.makeDefaultNode(url: URL(string: "http://5.161.53.74:36666")!),
            Node.makeDefaultNode(url: URL(string: "http://184.94.215.92:45555")!),
            Node.makeDefaultNode(
                url: URL(string: "https://node1.adamant.business")!,
                altUrl: URL(string: "http://194.233.75.29:45555")
            ),
            Node.makeDefaultNode(url: URL(string: "https://node2.blockchain2fa.io")!),
            Node.makeDefaultNode(
                url: URL(string: "https://phecda.adm.im")!,
                altUrl: URL(string: "http://46.250.234.248:36666")
            ),
            Node.makeDefaultNode(url: URL(string: "https://tegmine.adm.im")!),
            Node.makeDefaultNode(
                url: URL(string: "https://tauri.adm.im")!,
                altUrl: URL(string: "http://154.26.159.245:36666")
            ),
            Node.makeDefaultNode(url: URL(string: "https://dschubba.adm.im")!),
            Node.makeDefaultNode(
                url: URL(string: "https://tauri.bbry.org")!,
                altUrl: URL(string: "http://54.197.36.175:36666")
            ),
            Node.makeDefaultNode(
                url: URL(string: "https://endless.bbry.org")!,
                altUrl: URL(string: "http://54.197.36.175:46666")
            ),
            Node.makeDefaultNode(
                url: URL(string: "https://debate.bbry.org")!,
                altUrl: URL(string: "http://54.197.36.175:56666")
            )
        ]
    }
}
