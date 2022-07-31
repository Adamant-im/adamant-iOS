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
    
    weak var nodesSource: NodesSource! {
        didSet {
            refreshNode()
        }
    }
    
    // MARK: - Properties
    
    private(set) var currentNode: Node? {
        didSet {
            currentUrl = currentNode?.asSocketURL()
            
            guard oldValue !== currentNode else { return }
            sendCurrentNodeUpdateNotification()
        }
    }
    
    private var currentUrl: URL? {
        didSet {
            guard
                oldValue != currentUrl,
                let address = currentAddress,
                let handler = currentHandler
            else {
                return
            }
            
            connect(address: address, handler: handler)
        }
    }
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentAddress: String?
    private var currentHandler: ((ApiServiceResult<Transaction>) -> Void)?
    
    let defaultResponseDispatchQueue = DispatchQueue(
        label: "com.adamant.response-queue",
        qos: .utility
    )
    
    init() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.NodesSource.nodesUpdate,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.refreshNode()
        }
    }
    
    // MARK: - Tools
    
    func connect(address: String, handler: @escaping (ApiServiceResult<Transaction>) -> Void) {
        disconnect()
        currentAddress = address
        currentHandler = handler
        
        guard let currentUrl = currentUrl else { return }

        manager = SocketManager(
            socketURL: currentUrl,
            config: [.log(false), .compress]
        )
        
        socket = manager?.defaultSocket
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            self?.socket?.emit("address", with: [address])
        }
        
        socket?.on("newTrans") { [weak self] data, _ in
            self?.handleTransaction(data: data)
        }
        
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
    }
    
    private func refreshNode() {
        currentNode = nodesSource.getPreferredNode(needWS: true)
    }
    
    private func handleTransaction(data: [Any]) {
        guard
            let data = data.first,
            let dict = data as? [String: Any],
            let trans = try? JSONDecoder().decode(
                Transaction.self,
                from: JSONSerialization.data(withJSONObject: dict)
            ),
            trans.asset.chat?.type != .signal
        else {
            return
        }
        
        defaultResponseDispatchQueue.async { [currentHandler] in
            currentHandler?(.success(trans))
        }
    }
    
    private func sendCurrentNodeUpdateNotification() {
        NotificationCenter.default.post(
            name: Notification.Name.SocketService.currentNodeUpdate,
            object: self,
            userInfo: nil
        )
    }
}
