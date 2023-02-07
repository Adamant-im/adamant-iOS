//
//  ChatPreservationDelegate.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

protocol ChatPreservationDelegate: AnyObject {
    func preserveMessage(_ message: String, forAddress address: String)
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String?
}
