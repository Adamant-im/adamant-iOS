//
//  CustomCellDeleage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 28.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Custom cell
protocol TapRecognizerCustomCell: class {
    /// Must be a weak reference
    var delegate: CustomCellDelegate? { get set }
}

protocol CustomCellDelegate: class {
    func didTapCustomCell(_ cell: TapRecognizerCustomCell)
}

// MARK: - Transfer cell
protocol TapRecognizerTransferCell: class {
    // Must be a weak reference
    var delegate: TransferCellDelegate? { get set }
}

protocol TransferCellDelegate: class {
    func didTapTransferCell(_ cell: TapRecognizerTransferCell)
    func didTapTransferCellStatus(_ cell: TapRecognizerTransferCell)
}
