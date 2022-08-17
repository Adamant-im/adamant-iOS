//
//  AdamantHealthCheckServiceTests.swift
//  AdamantTests
//
//  Created by Andrey on 31.07.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class AdamantHealthCheckServiceTests: XCTestCase {
    var service: AdamantHealthCheckService!
    
    override func setUp() {
        super.setUp()
        service = .init()
        service.apiService = ApiServiceStub()
    }
    
    override func tearDown() {
        super.tearDown()
        service = nil
    }
    
    // MARK: - Allowed nodes tests without WS support
    
    func testOneAllowedNode() {
        let node = makeTestNode(connectionStatus: .allowed)
        service.nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: false))
    }
    
    func testOneNodeWithoutConnectionStatusIsAllowed() {
        let node = makeTestNode()
        service.nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: false))
    }
    
    func testOneDisabledNodeIsNotAllowed() {
        let node = makeTestNode()
        node.isEnabled = false
        service.nodes = [node]
        
        XCTAssert(allowedNodes(ws: false).isEmpty)
    }
    
    func testOneOfflineNodeIsAllowed() {
        let node = makeTestNode(connectionStatus: .offline)
        service.nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: false))
    }
    
    func testManyAllowedNodesSortedBySpeedDescending() {
        let nodes: [Node] = (0 ..< 100).map { ping in
            let node = makeTestNode(connectionStatus: .allowed)
            node.status = .init(ping: TimeInterval(ping), wsEnabled: false, height: nil, version: nil)
            return node
        }
        
        service.nodes = nodes.shuffled()
        
        XCTAssertEqual(nodes, allowedNodes(ws: false))
    }
    
    // MARK: - Allowed nodes tests with WS support
    
    func testOneAllowedNodeWithoutWSIsNotAllowedWS() {
        let node = makeTestNode(connectionStatus: .allowed)
        node.status = .init(ping: .zero, wsEnabled: false, height: nil, version: nil)
        service.nodes = [node]
        
        XCTAssert(allowedNodes(ws: true).isEmpty)
    }
    
    func testOneAllowedWSNodeIsAllowedWS() {
        let node = makeTestNode(connectionStatus: .allowed)
        node.status = .init(ping: .zero, wsEnabled: true, height: nil, version: nil)
        service.nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: true))
    }
    
    func testOneWSNodeWithoutConnectionStatusIsNotAllowedWS() {
        let node = makeTestNode()
        node.status = .init(ping: .zero, wsEnabled: true, height: nil, version: nil)
        service.nodes = [node]
        
        XCTAssert(allowedNodes(ws: true).isEmpty)
    }
    
    func testManyAllowedNodesSortedBySpeedDescendingWS() {
        let nodes: [Node] = (0 ..< 100).map { ping in
            let node = makeTestNode(connectionStatus: .allowed)
            node.status = .init(ping: TimeInterval(ping), wsEnabled: true, height: nil, version: nil)
            return node
        }
        
        service.nodes = nodes.shuffled()
        
        XCTAssertEqual(nodes, allowedNodes(ws: true))
    }
    
    // MARK: - Health check tests
    
    func testOneNodeWithoutStatusIsSync() {
        let node = makeTestNode()
        
        service.nodes = [node]
        service.healthCheck()
        
        XCTAssertEqual(node.connectionStatus, .synchronizing)
    }
    
    func testOneNodeWithStatusIsAllowed() {
        let node = makeTestNode()
        node.status = .init(ping: .zero, wsEnabled: false, height: .zero, version: nil)
        
        service.nodes = [node]
        service.healthCheck()
        
        XCTAssertEqual(node.connectionStatus, .allowed)
    }
    
    func testTwoNodesWithSameHeightsAreAllowed() {
        let nodes: [Node] = (0 ..< 2).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 1000, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 1000, version: nil)
        
        service.nodes = nodes
        service.healthCheck()
        
        XCTAssertEqual(nodes[0].connectionStatus, .allowed)
        XCTAssertEqual(nodes[1].connectionStatus, .allowed)
    }
    
    func testTwoNodes_HighestIsAllowed() {
        let nodes: [Node] = (0 ..< 2).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 1000, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 1001, version: nil)
        
        service.nodes = nodes
        service.healthCheck()
        
        XCTAssertEqual(nodes[0].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[1].connectionStatus, .allowed)
    }
    
    func testSeveralNodesWithEpsilonHeightsIntervalAreAllowed() {
        let nodes: [Node] = (0 ..< 3).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 0, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 10, version: nil)
        nodes[2].status = .init(ping: .zero, wsEnabled: false, height: 20, version: nil)
        
        service.nodes = nodes
        service.healthCheck()
        
        XCTAssertEqual(nodes[0].connectionStatus, .allowed)
        XCTAssertEqual(nodes[1].connectionStatus, .allowed)
        XCTAssertEqual(nodes[2].connectionStatus, .allowed)
    }
    
    func testSeveralNodesWithEpsilonPlusOneHeightsInterval_HighestIsAllowed() {
        let nodes: [Node] = (0 ..< 3).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 0, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 11, version: nil)
        nodes[2].status = .init(ping: .zero, wsEnabled: false, height: 22, version: nil)
        
        service.nodes = nodes
        service.healthCheck()
        
        XCTAssertEqual(nodes[0].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[1].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[2].connectionStatus, .allowed)
    }
    
    func testSeveralValidIntervals_HighestIntervalIsAllowed() {
        let nodes: [Node] = (0 ..< 5).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 0, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 10, version: nil)
        nodes[2].status = .init(ping: .zero, wsEnabled: false, height: 20, version: nil)
        nodes[3].status = .init(ping: .zero, wsEnabled: false, height: 30, version: nil)
        nodes[4].status = .init(ping: .zero, wsEnabled: false, height: 40, version: nil)
        
        service.nodes = nodes
        service.healthCheck()
        
        XCTAssertEqual(nodes[0].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[1].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[2].connectionStatus, .allowed)
        XCTAssertEqual(nodes[3].connectionStatus, .allowed)
        XCTAssertEqual(nodes[4].connectionStatus, .allowed)
    }
    
    // MARK: - Helpers
    
    private func allowedNodes(ws: Bool) -> [Node] {
        service.getAllowedNodes(sortedBySpeedDescending: true, needWS: ws)
    }
    
    private func makeTestNode(connectionStatus: Node.ConnectionStatus = .synchronizing) -> Node {
        let node = Node(scheme: .default, host: "", port: nil)
        node.connectionStatus = connectionStatus
        return node
    }
}
