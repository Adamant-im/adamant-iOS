//
//  AnsApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire

enum AnsApiServiceResult {
	case success
	case failure(ApiServiceError)
}

class AnsApiService {
	struct ApiCommants {
		static let register = "/api/reg"
		
		private init() {}
	}
	
	func register(token: String, completion: @escaping (AnsApiServiceResult) -> Void) {
		
	}
}
