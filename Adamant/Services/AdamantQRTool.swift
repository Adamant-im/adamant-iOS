//
//  AdamantQRTool.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import EFQRCode

class AdamantQRTool: QRTool {
	func generateQrFrom(passphrase: String) -> QRToolGenerateResult {
		guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
			return .invalidFormat
		}
		
		if let qr = EFQRCode.generate(content: passphrase) {
			let image = UIImage(cgImage: qr)
			return .success(image)
		}
		
		return .failure(error: AdamantError(message: "Failed to generate QR from: \(passphrase)"))
	}
	
	func readQR(_ qr: UIImage) -> QRToolDecodeResult {
		guard let image = qr.cgImage else {
			print("Failed to get image?")
			return .none
		}
		
		if let result = EFQRCode.recognize(image: image)?.first {
			if AdamantUtilities.validateAdamantPassphrase(passphrase: result) {
				return .passphrase(result)
			}
		}
		
		return .none
	}
}
