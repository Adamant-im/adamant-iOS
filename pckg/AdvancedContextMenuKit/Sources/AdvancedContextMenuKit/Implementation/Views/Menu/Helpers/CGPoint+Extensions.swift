//
//  CGPoint+Extensions.swift
//  
//
//  Created by Franklyn Weber on 10/03/2021.
//

import UIKit

extension CGPoint {
    
    // though CGPoint isn't a vector, Apple uses it in places where a CGVector would be more appropriate
    public var magnitude: CGFloat {
        return sqrt(x * x + y * y)
    }
    
    public static func +(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    public static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
