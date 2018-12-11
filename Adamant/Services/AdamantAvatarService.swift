//
//  AdamantAvatarService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 30/08/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreGraphics
import CryptoSwift
import GameplayKit

class AdamantAvatarService: AvatarService {
    
    private let colors: [[UIColor]] = [
        [
            UIColor(hex: "#ffffff"), //background
            UIColor(hex: "#179cec"), // main
            UIColor(hex: "#8bcef6"), // 2dary
            UIColor(hex: "#c5e6fa") // 2dary
        ],
        [
            UIColor(hex: "#ffffff"), //background
            UIColor(hex: "#32d296"), // main
            UIColor(hex: "#99e9cb"), // 2dary
            UIColor(hex: "#ccf4e5") // 2dary
        ],
        [
            UIColor(hex: "#ffffff"), //background
            UIColor(hex: "#faa05a"), // main
            UIColor(hex: "#fdd0ad"), // 2dary
            UIColor(hex: "#fee7d6") // 2dary
        ],
        [
            UIColor(hex: "#ffffff"), //background
            UIColor(hex: "#474a5f"), // main
            UIColor(hex: "#a3a5af"), // 2dary
            UIColor(hex: "#d1d2d7") // 2dary
        ],
        [
            UIColor(hex: "#ffffff"), //background
            UIColor(hex: "#9497a3"), // main
            UIColor(hex: "#cacbd1"), // 2dary
            UIColor(hex: "#e4e5e8") // 2dary
        ]
    ]
    
    private var cache: [String: UIImage] = [String: UIImage]()
    
    func avatar(for key:String, size: Double = 200) -> UIImage {
        if let image = cache[key] {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        Hexa16(key: key, colors: colors, size: size)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let image = image {
            cache[key] = image
            
            return image
        } else {
            return UIImage()
        }
    }
    
    func Hexa16(key: String, colors: [[UIColor]], size: Double) {
        let fringeSize = size / 6
        let distance = distanceTo3rdPoint(fringeSize)
        let lines = size / fringeSize
        let offset = ((fringeSize - distance) * lines) / 2
        
        let fillTriangle = triangleColors(0, key, colors, Int(lines))
        let transparent = UIColor.clear
        
        let isLeft: (Int)->Bool = { (v: Int) -> Bool in return (v % 2) == 0 }
        let isRight: (Int)->Bool = { (v: Int) -> Bool in return (v % 2) != 0 }
        
        let L = Int(lines)
        let hL = L / 2
        
        for xL in 0 ..< hL {
            for yL in 0 ..< L {
                if isOutsideHexagon(xL, yL, Int(lines)) {
                    continue
                }
                
                var x1, x2, y1, y2, y3: Double
                if (xL % 2) == 0 {
                    let result = right1stTriangle(Double(xL), Double(yL), fringeSize, distance)
                    x1 = result.x1
                    y1 = result.y1
                    x2 = result.x2
                    y2 = result.y2
                    y3 = result.y3
                } else {
                    let result = left1stTriangle(Double(xL), Double(yL), fringeSize, distance)
                    x1 = result.x1
                    y1 = result.y1
                    x2 = result.x2
                    y2 = result.y2
                    y3 = result.y3
                }

                let xs = [x2 + offset, x1 + offset, x2 + offset]
                let ys = [y1, y2, y3]

                if let fill = canFill(xL, yL, fillTriangle, isLeft, isRight) {
                    Polygon(xs, ys, fill)
                } else {
                    Polygon(xs, ys, transparent)
                }

                let xsMirror = mirrorCoordinates(xs, lines, distance, offset * 2)
                let xLMirror = lines - Double(xL) - 1.0
                let yLMirror = yL

                if let fill = canFill(Int(xLMirror), yLMirror, fillTriangle, isLeft, isRight) {
                    Polygon(xsMirror, ys, fill)
                } else {
                    Polygon(xsMirror, ys, transparent)
                }
                
                var x11, x12, y11, y12, y13: Double
                if (xL % 2) == 0 {
                    let result = left2ndTriangle(Double(xL), Double(yL), fringeSize, distance)
                    x11 = result.x1
                    y11 = result.y1
                    x12 = result.x2
                    y12 = result.y2
                    y13 = result.y3
                    
                    // in order to have a perfect hexagon,
                    // we make sure that the previous triangle and this one touch each other in this point.
                    y12 = y3
                } else {
                    let result = right2ndTriangle(Double(xL), Double(yL), fringeSize, distance)
                    x11 = result.x1
                    y11 = result.y1
                    x12 = result.x2
                    y12 = result.y2
                    y13 = result.y3
                    
                    // in order to have a perfect hexagon,
                    // we make sure that the previous triangle and this one touch each other in this point.
                    y12 = y1 + fringeSize
                }
                
                var xs1 = [x12 + offset, x11 + offset, x12 + offset]
                let ys1 = [y11, y12, y13]
                
                // triangles that go to the right
                
                if let fill = canFill(xL, yL, fillTriangle, isRight, isLeft) {
                    Polygon(xs1, ys1, fill)
                } else {
                    Polygon(xs1, ys1, transparent)
                }
                
                xs1 = mirrorCoordinates(xs1, lines, distance, offset * 2)
                
                if let fill = canFill(Int(xLMirror), yLMirror, fillTriangle, isRight, isLeft) {
                    Polygon(xs1, ys1, fill)
                } else {
                    Polygon(xs1, ys1, transparent)
                }
            }
        }
    }
    
    func Polygon(_ xs: [Double], _ ys: [Double], _ color: UIColor) {
        let polygonPath = UIBezierPath()
        
        for (i, x) in xs.enumerated() {
            let y = ys[i]
            let p = CGPoint(x: x, y: y)
            
            if i == 0 {
                polygonPath.move(to: p)
            } else {
                polygonPath.addLine(to: p)
            }
        }
        
        polygonPath.close()
        color.setFill()
        polygonPath.fill()
    }
    
    func distanceTo3rdPoint(_ AC: Double) -> Double {
        // distance from center of vector to third point of equilateral triangles
        // ABC triangle, O is the center of AB vector
        // OC = SQRT(AC^2 - AO^2)
        return ceil(sqrt((AC * AC) - (AC/2 * AC/2)))
    }
    
    // right1stTriangle computes a right oriented triangle '>'
    func right1stTriangle(_ xL: Double, _ yL: Double, _ fringeSize: Double, _ distance: Double) -> (x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double) {
        let x1 = xL * distance
        let x2 = xL * distance + distance
        let x3 = x1
        let y1 = yL * fringeSize
        let y2 = y1 + fringeSize / 2
        let y3 = yL * fringeSize + fringeSize
        return (x1, y1, x2, y2, x3, y3)
    }
    
    // left1stTriangle computes the coordinates of a left oriented triangle '<'
    func left1stTriangle(_ xL: Double, _ yL: Double, _ fringeSize: Double, _ distance: Double) -> (x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double) {
        let x1 = xL * distance + distance
        let x2 = xL * distance
        let x3 = x1
        let y1 = yL * fringeSize
        let y2 = y1 + fringeSize / 2
        let y3 = yL * fringeSize + fringeSize
        return (x1, y1, x2, y2, x3, y3)
    }
    
    // left2ndTriangle computes the coordinates of a left oriented triangle '<'
    func left2ndTriangle(_ xL: Double, _ yL: Double, _ fringeSize: Double, _ distance: Double) -> (x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double) {
        let x1 = xL * distance + distance
        let x2 = xL * distance
        let x3 = x1
        let y1 = yL * fringeSize + fringeSize / 2
        let y2 = y1 + fringeSize / 2
        let y3 = yL * fringeSize + fringeSize + fringeSize / 2
        return (x1, y1, x2, y2, x3, y3)
    }
    
    // right2ndTriangle computes the coordinates of a right oriented triangle '>'
    func right2ndTriangle(_ xL: Double, _ yL: Double, _ fringeSize: Double, _ distance: Double) -> (x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double) {
        let x1 = xL * distance
        let x2 = xL * distance + distance
        let x3 = x1
        let y1 = yL * fringeSize + fringeSize / 2
        let y2 = yL + fringeSize
        let y3 = yL * fringeSize + fringeSize / 2 + fringeSize
        return (x1, y1, x2, y2, x3, y3)
    }
    
    func mirrorCoordinates(_ xs: [Double], _ lines: Double, _ fringeSize: Double, _ offset: Double) -> [Double] {
        var xsMirror = [Double]()
        for (_, v) in xs.enumerated() {
            xsMirror.append((lines * fringeSize) - v + offset)
        }
        return xsMirror
    }
    
    func triangleColors(_ id: Int, _ key: String, _ colors: [[UIColor]], _ lines: Int) -> [UIColor] {
        var tColors = [UIColor]()
        
        var seed: UInt64 = 0
        for u in key.md5().unicodeScalars {
            seed += UInt64(u)
        }
        
        let rndSrc = GKLinearCongruentialRandomSource(seed: scramble(seed: seed))
        let rnd = GKRandomDistribution(randomSource: rndSrc,
                                         lowestValue: 0,
                                         highestValue: Int(Int32.max/2))
        
        let colors = colors[rnd.nextInt() % colors.count]
        
        for t in Triangle.triangles[id] {
            let x = t.x
            let y = t.y
            let index = (x + 3 * y + lines + rnd.nextInt()) % 15
            let color = PickColor(key, colors, index: index)
            tColors.append(color)
        }
        return tColors
    }
    
    func scramble( seed : UInt64 ) -> UInt64 {
        let multiplier : UInt64 = 0x5DEECE66D
        let mask : UInt64 = (1 << 48) - 1
        
        return (seed ^ multiplier) & mask;
    }
    
    func isOutsideHexagon(_ xL: Int, _ yL: Int, _ lines: Int) -> Bool {
        return !isFill1InHexagon(xL, yL, lines) && !isFill2InHexagon(xL, yL, lines)
    }
    
    func isFill1InHexagon(_ xL: Int, _ yL: Int, _ lines: Int) -> Bool {
        let half = lines / 2
        let start = half / 2
        if xL < start+1 {
            if yL > start-1 && yL < start+half+1 {
                return true
            }
        }
        if xL == half-1 {
            if yL > start-1-1 && yL < start+half+1+1 {
                return true
            }
        }
        return false
    }
    
    func isFill2InHexagon(_ xL: Int, _ yL: Int, _ lines: Int) -> Bool {
        let half = lines / 2
        let start = half / 2
        
        if xL < start {
            if yL > start-1 && yL < start+half {
                return true
            }
        }
        if xL == 1 {
            if yL > start-1-1 && yL < start+half+1 {
                return true
            }
        }
        if xL == half-1 {
            if yL > start-1-1 && yL < start+half+1 {
                return true
            }
        }
        return false
    }
    
    // PickColor returns a color given a key string, an array of colors and an index.
    // key: should be a md5 hash string.
    // index: is an index from the key string. Should be in interval [0, 16]
    // Algorithm: PickColor converts the key[index] value to a decimal value.
    // We pick the ith colors that respects the equality value%numberOfColors == i.
    func PickColor(_ key: String, _ colors: [UIColor], index: Int) -> UIColor {
        let n = colors.count
        let i = PickIndex(key, n, index)
        return colors[i]
    }
    
    // PickIndex returns an index of given a key string, the size of an array of colors
    //  and an index.
    // key: should be a md5 hash string.
    // index: is an index from the key string. Should be in interval [0, 16]
    // Algorithm: PickIndex converts the key[index] value to a decimal value.
    // We pick the ith index that respects the equality value%sizeOfArray == i.
    func PickIndex(_ key: String, _ n: Int, _ index: Int) -> Int {
        let s = String(key.md5()[index])
        let r = Int([UInt8](s.utf8).first ?? 0)
        for i in 0 ..< n {
            if r%n == i {
                return i
            }
        }
        return 0
    }
    
    // canFill returns a fill svg string given position. the fill is computed to be a rotation of the
    // triangle 0 with the 'fills' array given as param.
    func canFill(_ x: Int, _ y: Int, _ fills: [UIColor], _ isLeft: (Int)->Bool, _ isRight: (Int)->Bool) -> UIColor? {
        let l = Triangle(x, y, .left)
        let r = Triangle(x, y, .right)
        
        if isLeft(x) && l.isInTriangle() {
            let rid = l.rotationID()
            return fills[rid]
        } else if isRight(x) && r.isInTriangle() {
            let rid = r.rotationID()
            return fills[rid]
        }
        return nil
    }
}

fileprivate struct Triangle {
    let x: Int
    let y: Int
    let direction: Direction
    
    // triangles in an array of arrray triangle positions.
    // each array correspond to a triangle, there are 6 of them,
    // indexes from 0 to 5, they form an hexagon.
    // each triangle to composed of 9 subtriangles ordered
    // from up left to down right
    static let triangles: [[Triangle]] = [
        [
            Triangle(0, 1, .right),
            Triangle(0, 2, .right),
            Triangle(0, 3, .right),
            Triangle(0, 2, .left),
            Triangle(0, 3, .left),
            Triangle(1, 2, .right),
            Triangle(1, 3, .right),
            Triangle(1, 2, .left),
            Triangle(2, 2, .right)
        ],
        [
            Triangle(0, 1, .left),
            Triangle(1, 1, .right),
            Triangle(1, 0, .left),
            Triangle(1, 1, .left),
            Triangle(2, 0, .right),
            Triangle(2, 1, .right),
            Triangle(2, 0, .left),
            Triangle(2, 1, .left),
            Triangle(2, 2, .left)
        ],
        [
            Triangle(3, 0, .right),
            Triangle(3, 1, .right),
            Triangle(3, 2, .right),
            Triangle(3, 0, .left),
            Triangle(3, 1, .left),
            Triangle(4, 0, .right),
            Triangle(4, 1, .right),
            Triangle(4, 1, .left),
            Triangle(5, 1, .right)
        ],
        [
            Triangle(3, 2, .left),
            Triangle(4, 2, .right),
            Triangle(4, 2, .left),
            Triangle(4, 3, .left),
            Triangle(5, 2, .right),
            Triangle(5, 3, .right),
            Triangle(5, 1, .left),
            Triangle(5, 2, .left),
            Triangle(5, 3, .left)
        ],
        [
            Triangle(3, 3, .right),
            Triangle(3, 4, .right),
            Triangle(3, 5, .right),
            Triangle(3, 3, .left),
            Triangle(3, 4, .left),
            Triangle(4, 3, .right),
            Triangle(4, 4, .right),
            Triangle(4, 4, .left),
            Triangle(5, 4, .right)
        ],
        [
            Triangle(0, 4, .left),
            Triangle(1, 4, .right),
            Triangle(1, 3, .left),
            Triangle(1, 4, .left),
            Triangle(2, 3, .right),
            Triangle(2, 4, .right),
            Triangle(2, 3, .left),
            Triangle(2, 4, .left),
            Triangle(2, 5, .left)
        ]
    ]
    
    init(_ x: Int, _ y: Int, _ direction: Direction) {
        self.x = x
        self.y = y
        self.direction = direction
    }
    
    func isInTriangle() -> Bool {
        return self.triangleID() != -1
    }
    
    // triangleID returns the triangle id (from 0 to 5)
    // that has a match with the position given as param.
    // returns -1 if a match is not found.
    func triangleID() -> Int {
        for (i, t) in Triangle.triangles.enumerated() {
            for ti in t {
                if ti.x == self.x && ti.y == self.y && self.direction == ti.direction {
                    return i
                }
            }
        }
        return -1
    }
    
    // subTriangleID returns the sub triangle id (from 0 to 8)
    // that has a match with the position given as param.
    // returns -1 if a match is not found.
    func subTriangleID() -> Int {
        for (_, t) in Triangle.triangles.enumerated() {
            for (i, ti) in t.enumerated() {
                if ti.x == self.x && ti.y == self.y && self.direction == ti.direction {
                    return i
                }
            }
        }
        return -1
    }
    
    func subTriangleRotations(_ lookforSubTriangleID: Int) -> [Int]? {
        let m: [Int:[Int]] = [
            0: [0, 6, 8, 8, 2, 0],
            1: [1, 2, 5, 7, 6, 3],
            2: [2, 0, 0, 6, 8, 8],
            3: [3, 4, 7, 5, 4, 1],
            4: [4, 1, 3, 4, 7, 5],
            5: [5, 7, 6, 3, 1, 2],
            6: [6, 3, 1, 2, 5, 7],
            7: [7, 5, 4, 1, 3, 4],
            8: [8, 8, 2, 0, 0, 6],
            ]
        return m[lookforSubTriangleID]
    }
    
    // rotationId returns the original sub triangle id
    // if the current triangle was rotated to position 0.
    func rotationID() -> Int {
        let currentTID = self.triangleID()
        let currentSTID = self.subTriangleID()
        let numberOfSubTriangles = 9
        for i in 0 ..< numberOfSubTriangles {
            if let rotations = subTriangleRotations(i) {
                if rotations[currentTID] == currentSTID {
                    return i
                }
            }
        }
        return -1
    }
}

fileprivate enum Direction: Int {
    case left = 0
    case right
}
