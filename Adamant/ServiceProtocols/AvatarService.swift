//
//  AvatarService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 03/09/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

protocol AvatarService {
    func avatar(for key:String, size: Double) -> UIImage
}
