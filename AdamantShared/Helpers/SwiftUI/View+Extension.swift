//
//  View+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func withoutListBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self.onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
        }
    }
}
