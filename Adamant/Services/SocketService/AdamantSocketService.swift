//
//  AdamantSocketService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.04.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import SocketIO
import CommonKit
import Combine

final class AdamantSocketService: SocketService, @unchecked Sendable {
    private let nodesStorage: NodesStorageProtocol
    private let nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol
    
    // MARK: - Properties
    
    @Atomic private(set) var currentNode: Node? {
        didSet {
            currentUrl = currentNode?.asSocketURL()
            
            guard oldValue?.id != currentNode?.id else { return }
            sendCurrentNodeUpdateNotification()
        }
    }
    
    @Atomic private var currentUrl: URL? {
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
    
    @Atomic private var manager: SocketManager?
    @Atomic private var socket: SocketIOClient?
    @Atomic private var currentAddress: String?
    @Atomic private var currentHandler: (@Sendable (ApiServiceResult<Transaction>) -> Void)?
    @Atomic private var subscriptions = Set<AnyCancellable>()
    
    let defaultResponseDispatchQueue = DispatchQueue(
        label: "com.adamant.response-queue",
        qos: .utility
    )
    
    init(
        nodesStorage: NodesStorageProtocol,
        nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol
    ) {
        self.nodesAdditionalParamsStorage = nodesAdditionalParamsStorage
        self.nodesStorage = nodesStorage
        
        nodesStorage
            .getNodesPublisher(group: .adm)
            .combineLatest(nodesAdditionalParamsStorage.fastestNodeMode(group: .adm))
            .sink { [weak self] in self?.updateCurrentNode(nodes: $0.0, fastestNode: $0.1) }
            .store(in: &subscriptions)
    }
    
    // MARK: - Tools
    
    func connect(address: String, handler: @escaping @Sendable (ApiServiceResult<Transaction>) -> Void) {
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
            self?.socket?.emit("address", with: [address], completion: nil)
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
    
    private func updateCurrentNode(nodes: [Node], fastestNode: Bool) {
        let allowedNodes = nodes.getAllowedNodes(
            sortedBySpeedDescending: fastestNode,
            needWS: true
        )
        
        guard !fastestNode else {
            currentNode = allowedNodes.first
            return
        }
        
        guard let previousNode = currentNode else {
            currentNode = allowedNodes.randomElement()
            return
        }
        
        currentNode = allowedNodes.first { $0.isSame(previousNode) } ?? allowedNodes.randomElement()
    }
}
