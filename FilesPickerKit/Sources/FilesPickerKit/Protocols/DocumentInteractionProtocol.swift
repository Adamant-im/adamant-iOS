//
//  DocumentInteractionProtocol.swift
//  
//
//  Created by Stanislav Jelezoglo on 14.03.2024.
//

import Foundation

protocol DocumentInteractionProtocol {
    func open(url: URL, name: String, completion: (() -> Void)?)
}
