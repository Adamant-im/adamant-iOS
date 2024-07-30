//
//  NodesAllowanceTests.swift
//  AdamantTests
//
//  Created by Andrey on 05.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class NodesAllowanceTests: XCTest {
    var nodes = [Node]()
    
    override func setUp() {
        super.setUp()
        nodes = []
    }
    
    // MARK: - Allowed nodes tests without WS support
    
    func testOneAllowedNode() {
        let node = makeTestNode(connectionStatus: .allowed)
        nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: false))
    }
    
    func testOneNodeWithoutConnectionStatusIsAllowed() {
        let node = makeTestNode()
        nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: false))
    }
    
    func testOneDisabledNodeIsNotAllowed() {
        let node = makeTestNode()
        node.isEnabled = false
        nodes = [node]
        
        XCTAssert(allowedNodes(ws: false).isEmpty)
    }
    
    func testOneOfflineNodeIsAllowed() {
        let node = makeTestNode(connectionStatus: .offline)
        nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: false))
    }
    
    func testManyAllowedNodesSortedBySpeedDescending() {
        let nodes: [Node] = (0 ..< 100).map { ping in
            let node = makeTestNode(connectionStatus: .allowed)
            node.status = .init(ping: TimeInterval(ping), wsEnabled: false, height: nil, version: nil)
            return node
        }
        
        self.nodes = nodes.shuffled()
        
        XCTAssertEqual(nodes, allowedNodes(ws: false))
    }
    
    // MARK: - Allowed nodes tests with WS support
    
    func testOneAllowedNodeWithoutWSIsNotAllowedWS() {
        let node = makeTestNode(connectionStatus: .allowed)
        node.status = .init(ping: .zero, wsEnabled: false, height: nil, version: nil)
        self.nodes = [node]
        
        XCTAssert(allowedNodes(ws: true).isEmpty)
    }
    
    func testOneAllowedWSNodeIsAllowedWS() {
        let node = makeTestNode(connectionStatus: .allowed)
        node.status = .init(ping: .zero, wsEnabled: true, height: nil, version: nil)
        self.nodes = [node]
        
        XCTAssertEqual([node], allowedNodes(ws: true))
    }
    
    func testOneWSNodeWithoutConnectionStatusIsNotAllowedWS() {
        let node = makeTestNode()
        node.status = .init(ping: .zero, wsEnabled: true, height: nil, version: nil)
        self.nodes = [node]
        
        XCTAssert(allowedNodes(ws: true).isEmpty)
    }
    
    func testManyAllowedNodesSortedBySpeedDescendingWS() {
        let nodes: [Node] = (0 ..< 100).map { ping in
            let node = makeTestNode(connectionStatus: .allowed)
            node.status = .init(ping: TimeInterval(ping), wsEnabled: true, height: nil, version: nil)
            return node
        }
        
        self.nodes = nodes.shuffled()
        
        XCTAssertEqual(nodes, allowedNodes(ws: true))
    }
    
    // MARK: - Helpers
    
    private func allowedNodes(ws: Bool) -> [Node] {
        nodes.getAllowedNodes(sortedBySpeedDescending: true, needWS: ws)
    }
    
    private func makeTestNode(connectionStatus: NodeConnectionStatus = .synchronizing) -> Node {
        let node = Node(scheme: .default, host: "", port: nil)
        node.connectionStatus = connectionStatus
        return node
    }
}
