//
//  ReusableView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 03.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

public protocol ReusableView: UIView {
    func prepareForReuse()
}
