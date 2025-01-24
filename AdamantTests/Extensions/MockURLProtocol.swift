//
//  URLProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 15.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
import Foundation

final class MockURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)?
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    static var requestHandler: Handler?
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            XCTFail("No request handler provided")
            return
        }
        
        do {
            guard let (response, data) = try handler(request) else {
                client?.urlProtocolDidFinishLoading(self)
                XCTFail("No request handler provided")
                return
            }
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            XCTFail("Error handling request, url: \(String(describing: request.url)): error \(error)")
        }
    }
    
    override func stopLoading() {}
}

extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if (read == 0) {
                break  // added
            }
            self.append(buffer, count: read)
        }
        buffer.deallocate()
        
        input.close()
    }
}

extension MockURLProtocol {
    static func combineHandlers(_ prevHandler: Handler?, _ new: @escaping Handler) -> Handler {
        { request in            
            return try new(request) ?? prevHandler?(request)
        }
    }
}
