//
//  ToastView.swift
//  
//
//  Created by Andrey Golubenko on 07.12.2022.
//

import SwiftUI
import CommonKit

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Blur(style: Constants.blurStyle))
            .cornerRadius(Constants.cornerRadius)
            .padding(Constants.borderPadding)
    }
}
