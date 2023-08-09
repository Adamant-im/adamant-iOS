//
//  UIListItemModel.swift
//  
//
//  Created by Andrey Golubenko on 09.08.2023.
//

public protocol UIListItemModel {
    var viewType: any UIListItemView.Type { get }
    var viewModel: any UIListItemViewModel { get }
}
