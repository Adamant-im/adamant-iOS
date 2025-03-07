//
//  ChatViewController+NavigationControllerDelegate.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 07.03.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

extension ChatViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController === self {
            viewModel.checkForADMNodesAvailability()
        }
    }
}
