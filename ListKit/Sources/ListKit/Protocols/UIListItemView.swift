//
//  UIListItemView.swift
//  
//
//  Created by Andrey Golubenko on 09.08.2023.
//

import UIKit

public protocol UIListItemView: UIView {
    associatedtype Model: UIListItemViewModel
    
    var model: Model { get set }
}
