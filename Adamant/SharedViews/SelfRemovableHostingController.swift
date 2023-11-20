//
//  SelfRemovableHostingController.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

class SelfRemovableHostingController<T: View>: UIHostingController<T> {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard
            splitViewController == nil,
            let navigationController = navigationController,
            navigationController.viewControllers.count == 1
        else { return }
        
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
