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
	func generateQrFrom(string: String) -> QRToolGenerateResult {
		if let qr = EFQRCode.generate(content: string) {
			let image = UIImage(cgImage: qr)
			return .success(image)
		}
		
		return .failure(error: AdamantError(message: "Failed to generate QR from: \(string)"))
	}
	
	func readQR(_ qr: UIImage) -> QRToolDecodeResult {
		guard let image = qr.cgImage else {
			print("Failed to get image?")
			return .none
		}
		
		if let result = EFQRCode.recognize(image: image)?.first {
			return .success(result)
		}
		
		return .none
	}
}
