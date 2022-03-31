//
//  CustomCellDeleage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 28.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Custom cell
protocol TapRecognizerCustomCell: AnyObject {
    /// Must be a weak reference
    var delegate: CustomCellDelegate? { get set }
}

protocol CustomCellDelegate: AnyObject {
    func didTapCustomCell(_ cell: TapRecognizerCustomCell)
}

// MARK: - Transfer cell
protocol TapRecognizerTransferCell: AnyObject {
    // Must be a weak reference
    var delegate: TransferCellDelegate? { get set }
}

protocol TransferCellDelegate: AnyObject {
    func didTapTransferCell(_ cell: TapRecognizerTransferCell)
    func didTapTransferCellStatus(_ cell: TapRecognizerTransferCell)
}
