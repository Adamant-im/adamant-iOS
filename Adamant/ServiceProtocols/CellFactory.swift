//
//  CellFactory.swift
//  Adamant
//
//  Created by Pavel Anokhov on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

struct SharedCell: Equatable, Hashable {
    let cellIdentifier: String
    let defaultXibName: String
    let defaultRowHeight: CGFloat
    
    init(cellIdentifier: String, xibName: String, rowHeight: CGFloat) {
        self.cellIdentifier = cellIdentifier
        self.defaultXibName = xibName
        self.defaultRowHeight = rowHeight
    }
}

@MainActor
protocol CellFactory: AnyObject {
    func nib(for sharedCell: SharedCell) -> UINib?
    func cellInstance(for sharedCell: SharedCell) -> UITableViewCell?
}
