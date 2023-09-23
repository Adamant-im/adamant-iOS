//
//  ContactDescription.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public struct ContactDescription: Codable {
    public let displayName: String?
    
    public init(displayName: String?) {
        self.displayName = displayName
    }
}

/* JSON
 {
     "payload": {
         "U12345": {
         "displayName": "Some name"
         },
         "U12345": {
         "displayName": "Some name"
         },
         "U12345": {
         "displayName": "Some name"
         },
         "U12345": {
         "displayName": "Some name"
         },
         "U12345": {
         "displayName": "Some name"
         },
         "U12345": {
         "displayName": "Some name"
         }
     }
 }
*/
