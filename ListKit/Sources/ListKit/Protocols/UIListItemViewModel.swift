//
//  UIListItemViewModel.swift
//  
//
//  Created by Andrey Golubenko on 09.08.2023.
//

import CoreGraphics

public protocol UIListItemViewModel: Equatable {
    func height(width: CGFloat) -> CGFloat
}
