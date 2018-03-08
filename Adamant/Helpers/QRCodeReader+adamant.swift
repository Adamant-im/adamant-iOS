//
//  QRCodeReader+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import QRCodeReader

extension QRCodeReaderViewController {
	static func adamantQrCodeReader() -> QRCodeReaderViewController {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr ], captureDevicePosition: .back)
			$0.cancelButtonTitle = String.adamantLocalized.alert.cancel
			$0.showSwitchCameraButton = false
		}
		
		return QRCodeReaderViewController(builder: builder)
	}
}
