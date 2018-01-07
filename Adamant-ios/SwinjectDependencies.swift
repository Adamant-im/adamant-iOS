//
//  SwinjectDependencies.swift
//  Cosmeteria
//
//  Created by Павел Анохов on 31.08.17.
//  Copyright © 2017 METASHARKS. All rights reserved.
//

import Swinject
import SwinjectStoryboard

// MARK: Services
extension Container {
	func registerAdamantServices(coreJsUrl core: URL, utilitiesJsUrl utils: URL) {
		self.register(DialogService.self) { _ in SwinjectedDialogService() }.inObjectScope(.container)
		self.register(AdamantCore.self) { _ in try! JSAdamantCore(coreJsUrl: core, utilitiesJsUrl: utils) }
		
		self.register(ApiService.self) { r in AdamantApiService(adamantCore: r.resolve(AdamantCore.self)!) }.inObjectScope(.container)
		self.register(LoginService.self) { r in AdamantLoginService(apiService: r.resolve(ApiService.self)!) }.inObjectScope(.container)
	}
}
