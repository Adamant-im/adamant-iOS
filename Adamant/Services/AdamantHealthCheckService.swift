//
//  AdamantHealthCheckService.swift
//  Adamant
//
//  Created by Андрей on 06.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import Alamofire
import CommonKit

final class AdamantHealthCheckService: HealthCheckService {
    // MARK: - Dependencies
    
    private let apiService: ApiService
    
    // MARK: - Properties
    
    private var _nodes = [Node]()
    private var currentRequests = Set<DataRequest>()
    private let semaphore = DispatchSemaphore(value: 1)
    private let notifyingQueue = DispatchQueue(label: "com.adamant.health-check-notification")
    
    weak var delegate: HealthCheckDelegate?
    
    init(apiService: ApiService) {
        self.apiService = apiService
    }
    
    var nodes: [Node] {
        get {
            defer { semaphore.signal() }
            semaphore.wait()
            return _nodes
        }
        set {
            defer { semaphore.signal() }
            semaphore.wait()
            _nodes = newValue
        }
    }
    
    // MARK: - Tools
    
    func healthCheck() {
        defer { semaphore.signal() }
        semaphore.wait()
        
        resetRequests()
        updateNodesAvailability()

        _nodes.filter { $0.isEnabled }.forEach { node in
            guard !isRequestInProgress(for: node),
                  let request = updateNodeStatus(node: node)
            else { return }
            
            currentRequests.insert(request)
        }
    }
    
    private func isRequestInProgress(for node: Node) -> Bool {
        return currentRequests.contains { request in
            request.request?.url?.absoluteString.contains(node.host) ?? false
        }
    }
    
    private func updateNodesAvailability() {
        let workingNodes = _nodes.filter { $0.isWorking }
        
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: workingNodes.compactMap { $0.status?.height }
        )
        
        for node in workingNodes {
            node.connectionStatus = node.status?.height.map { height in
                actualHeightsRange?.contains(height) ?? false
                    ? .allowed
                    : .synchronizing
            } ?? .synchronizing
        }
        
        notifyingQueue.async { [weak delegate] in
            delegate?.healthCheckUpdate()
        }
    }
    
    private func updateNodeStatus(node: Node) -> DataRequest? {
        guard let nodeURL = node.asURL() else {
            node.connectionStatus = .offline
            node.status = nil
            return nil
        }
        
        let startTimestamp = Date().timeIntervalSince1970
        
        return apiService.getNodeStatus(url: nodeURL) { [weak self] result in
            switch result {
            case let .success(status):
                node.status = Node.Status(
                    status: status,
                    ping: Date().timeIntervalSince1970 - startTimestamp
                )
                if !node.isWorking {
                    node.connectionStatus = .synchronizing
                }
                node.wsPort = status.wsClient?.port
                self?.updateNodesAvailability()
            case let .failure(error):
                self?.processError(error: error, node: node)
            }
        }
    }
    
    private func processError(error: ApiServiceError, node: Node) {
        switch error {
        case .requestCancelled:
            break
        case .networkError, .serverError, .internalError, .notLogged, .accountNotFound, .commonError:
            node.connectionStatus = .offline
            node.status = nil
            updateNodesAvailability()
        }
    }
    
    private func resetRequests() {
        currentRequests.filter { $0.isFinished }.forEach {
            $0.cancel()
            currentRequests.remove($0)
        }
    }
}

private extension Node {
    var isWorking: Bool {
        switch connectionStatus {
        case .allowed, .synchronizing:
            return true
        case .offline, .none:
            return false
        }
    }
}

private extension Node.Status {
    init(status: NodeStatus, ping: TimeInterval) {
        self.init(
            ping: ping,
            wsEnabled: status.wsClient?.enabled ?? false,
            height: status.network?.height,
            version: status.version?.version
        )
    }
}

private struct NodeHeightsInterval {
    let range: ClosedRange<Int>
    var count: Int
}

private func getActualNodeHeightsRange(heights: [Int]) -> ClosedRange<Int>? {
    guard heights.count > 2 else { return heights.max().map { $0...$0 } }
    
    let heights = heights.sorted()
    var bestInterval: NodeHeightsInterval?
    
    for i in heights.indices {
        var currentInterval = NodeHeightsInterval(
            range: heights[i] - nodeHeightEpsilon ... heights[i] + nodeHeightEpsilon,
            count: 1
        )
        
        for j in stride(from: i + 1, to: heights.endIndex, by: 1) {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        for j in stride(from: i - 1, through: 0, by: -1) {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        if currentInterval.count >= bestInterval?.count ?? 0 {
            bestInterval = currentInterval
        }
    }
    
    return bestInterval?.range
}

private let nodeHeightEpsilon = 10
