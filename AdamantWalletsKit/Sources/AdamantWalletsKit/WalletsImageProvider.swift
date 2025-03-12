//
//  PackageResourceProvider.swift
//  AdamantWalletsKit
//
//  Created by Владимир Клевцов on 17.1.25..
//
import Foundation
import UIKit

public enum WalletsImageProvider {
    static public func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: .module, with: nil)
    }
}
