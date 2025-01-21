//
//  OverlayViewDelegate.swift
//  
//
//  Created by Stanislav Jelezoglo on 01.08.2023.
//

import Foundation

@MainActor
protocol OverlayViewDelegate: AnyObject {
    func willDissmis()
    func didDissmis()
    func didAppear()
}
