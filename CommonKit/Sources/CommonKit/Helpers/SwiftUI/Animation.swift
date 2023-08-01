//
//  Animation.swift
//  
//
//  Created by Stanislav Jelezoglo on 01.08.2023.
//

import SwiftUI

public func animate(duration: CGFloat, _ execute: @escaping () -> Void) async {
    await withCheckedContinuation { continuation in
        withAnimation(.easeInOut(duration: duration)) {
            execute()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            continuation.resume()
        }
    }
}
