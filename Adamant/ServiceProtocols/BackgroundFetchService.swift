//
//  BackgroundFetchService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum FetchResult {
	case newData
	case noData
	case failed
}

protocol BackgroundFetchService {
	func fetchBackgroundData(notificationsService: NotificationsService, completion: @escaping (FetchResult) -> Void)
	func dropStateData()
}
