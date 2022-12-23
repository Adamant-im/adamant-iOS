//
//  AlertModel.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit

struct AlertModel: Equatable, Hashable {
    let icon: Icon
    let message: String?
    let userInteractionEnabled: Bool
}

extension AlertModel {
    enum Icon: Equatable, Hashable {
        case loading
        case image(UIImage)
    }
}
