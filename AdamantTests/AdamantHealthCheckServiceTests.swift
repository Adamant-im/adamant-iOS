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
    }
    
    override func tearDown() {
        super.tearDown()
        service = nil
    }
    
    // MARK: - Preferred node tests without WS support
    
    func testOneAllowedNodeIsPreferred() {
        let node = makeTestNode(connectionStatus: .allowed)
        service.nodes = [node]
        
        XCTAssertEqual(node, preferredNode(ws: false))
    }
    
    func testOneNodeWithoutConnectionStatusIsPreferred() {
        let node = makeTestNode()
        service.nodes = [node]
        
        XCTAssertEqual(node, preferredNode(ws: false))
    }
    
    func testOneDisabledNodeIsNotPreferred() {
        let node = makeTestNode()
        node.isEnabled = false
        service.nodes = [node]
        
        XCTAssertNil(preferredNode(ws: false))
    }
    
    func testOneOfflineNodeIsNotPreferred() {
        let node = makeTestNode(connectionStatus: .offline)
        service.nodes = [node]
        
        XCTAssertNil(preferredNode(ws: false))
    }
    
    func testManyAllowedNodesFastestIsPreferred() {
        let nodes: [Node] = (0 ..< 100).map { _ in
            let node = makeTestNode(connectionStatus: .allowed)
            node.status = .init(ping: 100, wsEnabled: false, height: nil, version: nil)
            return node
        }
        
        nodes[10].status = .init(ping: 99, wsEnabled: false, height: nil, version: nil)
        service.nodes = nodes
        
        XCTAssertEqual(nodes[10], preferredNode(ws: false))
    }
    
    // MARK: - Preferred node tests with WS support
    
    func testOneAllowedNodeWithoutWSIsNotPreferredWS() {
        let node = makeTestNode(connectionStatus: .allowed)
        node.status = .init(ping: .zero, wsEnabled: false, height: nil, version: nil)
        service.nodes = [node]
        
        XCTAssertNil(preferredNode(ws: true))
    }
    
    func testOneAllowedWSNodeIsPreferredWS() {
        let node = makeTestNode(connectionStatus: .allowed)
        node.status = .init(ping: .zero, wsEnabled: true, height: nil, version: nil)
        service.nodes = [node]
        
        XCTAssertEqual(node, preferredNode(ws: true))
    }
    
    func testOneWSNodeWithoutConnectionStatusIsNotPreferredWS() {
        let node = makeTestNode()
        node.status = .init(ping: .zero, wsEnabled: true, height: nil, version: nil)
        service.nodes = [node]
        
        XCTAssertNil(preferredNode(ws: true))
    }
    
    func testManyAllowedWSNodesFastestIsPreferredWS() {
        let nodes: [Node] = (0 ..< 100).map { _ in
            let node = makeTestNode(connectionStatus: .allowed)
            node.status = .init(ping: 100, wsEnabled: true, height: nil, version: nil)
            return node
        }
        
        nodes[10].status = .init(ping: 99, wsEnabled: true, height: nil, version: nil)
        service.nodes = nodes
        
        XCTAssertEqual(nodes[10], preferredNode(ws: true))
    }
    
    // MARK: - Health check tests
    
    func testOneNodeWithoutStatusIsSync() {
        let node = makeTestNode()
        
        service.nodes = [node]
        service.updateNodesAvailability()
        
        XCTAssertEqual(node.connectionStatus, .synchronizing)
    }
    
    func testOneNodeWithStatusIsAllowed() {
        let node = makeTestNode()
        node.status = .init(ping: .zero, wsEnabled: false, height: .zero, version: nil)
        
        service.nodes = [node]
        service.updateNodesAvailability()
        
        XCTAssertEqual(node.connectionStatus, .allowed)
    }
    
    func testTwoNodesWithSameHeightsAreAllowed() {
        let nodes: [Node] = (0 ..< 2).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 1000, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 1000, version: nil)
        
        service.nodes = nodes
        service.updateNodesAvailability()
        
        XCTAssertEqual(nodes[0].connectionStatus, .allowed)
        XCTAssertEqual(nodes[1].connectionStatus, .allowed)
    }
    
    func testTwoNodes_HighestIsAllowed() {
        let nodes: [Node] = (0 ..< 2).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 1000, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 1001, version: nil)
        
        service.nodes = nodes
        service.updateNodesAvailability()
        
        XCTAssertEqual(nodes[0].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[1].connectionStatus, .allowed)
    }
    
    func testSeveralNodesWithEpsilonHeightsIntervalAreAllowed() {
        let nodes: [Node] = (0 ..< 3).map { _ in makeTestNode() }
        nodes[0].status = .init(ping: .zero, wsEnabled: false, height: 0, version: nil)
        nodes[1].status = .init(ping: .zero, wsEnabled: false, height: 10, version: nil)
        nodes[2].status = .init(ping: .zero, wsEnabled: false, height: 20, version: nil)
        
        service.nodes = nodes
        service.updateNodesAvailability()
        
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
        service.updateNodesAvailability()
        
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
        service.updateNodesAvailability()
        
        XCTAssertEqual(nodes[0].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[1].connectionStatus, .synchronizing)
        XCTAssertEqual(nodes[2].connectionStatus, .allowed)
        XCTAssertEqual(nodes[3].connectionStatus, .allowed)
        XCTAssertEqual(nodes[4].connectionStatus, .allowed)
    }
    
    // MARK: - Helpers
    
    private func preferredNode(ws: Bool) -> Node? {
        service.getPreferredNode(fastest: true, needWS: ws)
    }
    
    private func makeTestNode(connectionStatus: Node.ConnectionStatus = .synchronizing) -> Node {
        let node = Node(scheme: .default, host: "", port: nil)
        node.connectionStatus = connectionStatus
        return node
    }
}
