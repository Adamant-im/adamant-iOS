//
//  AdamantQRTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import EFQRCode
import CommonKit

enum QRToolGenerateResult {
    case success(UIImage)
    case failure(error: Error)
}

enum QRToolDecodeResult {
    case success(String)
    case none
    case failure(error: Error)
}

final class AdamantQRTools {
    static func generateQrFrom(string: String, withLogo: Bool = false ) -> QRToolGenerateResult {
        let generator = EFQRCodeGenerator(
            content: string,
            size: EFIntSize(width: 600, height: 600)
        )
        generator.withColors(backgroundColor: UIColor.white.cgColor, foregroundColor: UIColor.black.cgColor)
        if withLogo {
            let hasAdm = string.contains("\(AdmWalletService.qqPrefix):") || string.contains("msg.adamant.im")
            let logoSize = hasAdm ? EFIntSize(width: 156, height: 156) : EFIntSize(width: 138, height: 138)
            generator.withIcon(UIImage.asset(named: "logo")?.cgImage, size: logoSize)
        }
        
        if let qr = generator.generate() {
            let image = UIImage(cgImage: qr)
            return .success(image)
        }
        
        return .failure(error: AdamantError(message: "Failed to generate QR from: \(string)"))
    }
    
    static func readQR(_ qr: UIImage) -> QRToolDecodeResult {
        guard let image = qr.cgImage else {
            print("Failed to get image?")
            return .none
        }
        
        if let result = EFQRCode.recognize(image).first {
            return .success(result)
        }
        
        return .none
    }
    
    private init() {}
}
