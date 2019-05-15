//
//  PrivateKeyGenerator.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

protocol PrivateKeyGenerator {
    var rowTitle: String { get }
    var rowImage: UIImage? { get }
    func generatePrivateKeyFor(passphrase: String) -> String?
}
