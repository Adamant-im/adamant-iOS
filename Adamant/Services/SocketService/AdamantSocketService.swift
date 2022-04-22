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
            //nodesSource.migrate()
           // refreshNode()
        }
    }
    
    private let manager = SocketManager(socketURL: URL(string: "https://endless.adamant.im")!, config: [.log(true), .compress])
    private var socket:SocketIOClient?
    
    let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.response-queue", qos: .utility, attributes: [.concurrent])
    
    func connect(address: String) {
        socket = manager.defaultSocket
        socket?.on(clientEvent: .connect, callback: {[weak self] _, _ in
            self?.socket?.emit("address", with: [address])
        })
        socket?.connect()
    }
    
    func receiveNewTransaction(completion: ((ApiServiceResult<Transaction>) -> Void)?) {
        socket?.on("newTrans", callback: { [weak self] data, ack in
            guard let data = data.first else { return }
            guard let dict = data as? [String: Any] else { return }
            if let trans = try? JSONDecoder().decode(Transaction.self, from: JSONSerialization.data(withJSONObject: dict)) {
                self?.defaultResponseDispatchQueue.async {
                    completion?(.success(trans))
                }
            }
        })
    }
    
}
