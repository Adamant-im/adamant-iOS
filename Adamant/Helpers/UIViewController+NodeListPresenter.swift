//
//  UIViewController+NodeListPresenter.swift
//  Adamant
//
//  Created by Yana Silosieva on 31.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension UIViewController {
    func presentNodeListVC(screensFactory: ScreensFactory, node: NodeGroup) {
        let vc = node == .adm
        ? screensFactory.makeNodesList()
        : screensFactory.makeCoinsNodesList(context: .menu)
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        self.present(nav, animated: true, completion: nil)
    }
}
