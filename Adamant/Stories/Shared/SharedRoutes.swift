//
//  SharedRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 17.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
	struct Shared {
		static let shareQr = AdamantScene(identifier: "ShareQrViewController", factory: { r in
			let controller = ShareQrViewController(nibName: "ShareQrViewController", bundle: nil)
			controller.dialogService = r.resolve(DialogService.self)
			return controller
		})
	}
}
