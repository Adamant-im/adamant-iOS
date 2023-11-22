//
//  SelfRemovableHostingController.swift
//  Adamant
//
//  Created by Andrew G on 22.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

class SelfRemovableHostingController<T: View>: UIHostingController<T> {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
}

