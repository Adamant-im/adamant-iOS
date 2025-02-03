//
//  URLSessionSwizzlingMock.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation

final class URLSessionSwizzlingHolder {
    static var _stubbedUrlSessionConfiguration: URLSessionConfiguration?
}

extension URLSession {
    
    // Perform the swizzling
    static func swizzleInitializer() {
        let originalSelector = #selector(URLSession.init(configuration:delegate:delegateQueue:))
        let swizzledSelector = #selector(URLSession.swizzledInit)
        
        guard let originalMethod = class_getClassMethod(URLSession.self, originalSelector),
              let swizzledMethod = class_getClassMethod(URLSession.self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // Swizzled init with custom configuration
    @objc class func swizzledInit(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue queue: OperationQueue?) -> URLSession {
        swizzledInit(configuration: URLSessionSwizzlingHolder._stubbedUrlSessionConfiguration ?? configuration, delegate: delegate, delegateQueue: queue)
    }
}
