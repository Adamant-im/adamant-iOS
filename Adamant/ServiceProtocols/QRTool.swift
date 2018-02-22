//
//  QRTool.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

enum QRToolGenerateResult {
	case success(UIImage)
	case failure(error: Error)
}

enum QRToolDecodeResult {
	case success(String)
	case none
	case failure(error: Error)
}

protocol QRTool {
	func generateQrFrom(string: String) -> QRToolGenerateResult
	func readQR(_ qr: UIImage) -> QRToolDecodeResult
}
