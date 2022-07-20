//
//  AdamantSocketService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.04.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import SocketIO

class AdamantSocketService: SocketService {

    // MARK: - Dependencies
    
    var adamantCore: AdamantCore!
    var nodesSource: NodesSource! {
        didSet {
            refreshNode()
        }
    }
    
    // MARK: - Properties
    
    private(set) var node: Node? {
        didSet {
            currentUrl = node?.asSocketURL()
        }
    }
    
    private var currentUrl: URL?
    
    private var manager: SocketManager!
    private var socket: SocketIOClient?
    
    let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.response-queue", qos: .utility, attributes: [.concurrent])
    
    // MARK: - Tools
    
    func refreshNode() {
        node = nodesSource?.getSocketNewNode()
    }
    
    func connect(address: String) {
        guard let currentUrl = currentUrl else { return }
        manager = SocketManager(socketURL: currentUrl, config: [.log(false), .compress])
        socket = manager.defaultSocket
        socket?.on(clientEvent: .connect, callback: {[weak self] _, _ in
            self?.socket?.emit("address", with: [address])
        })
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func receiveNewTransaction(completion: ((ApiServiceResult<Transaction>) -> Void)?) {
        socket?.on("newTrans", callback: { [weak self] data, _ in
            guard let data = data.first else { return }
            guard let dict = data as? [String: Any] else { return }
            if let trans = try? JSONDecoder().decode(Transaction.self, from: JSONSerialization.data(withJSONObject: dict)),
               trans.asset.chat?.type != .signal {
                self?.defaultResponseDispatchQueue.async {
                    completion?(.success(trans))
                }
            }
        })
    }
    
}
