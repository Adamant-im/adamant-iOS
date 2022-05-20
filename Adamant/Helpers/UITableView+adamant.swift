//
//  UITableView+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func indicatorView() -> UIActivityIndicatorView{
        var activityIndicatorView = UIActivityIndicatorView()
        if self.tableFooterView == nil {
            let indicatorFrame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 60)
            activityIndicatorView = UIActivityIndicatorView(frame: indicatorFrame)
            activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
            
            if #available(iOS 13.0, *) {
                activityIndicatorView.style = .medium
            } else {
                activityIndicatorView.style = .gray
            }
            
            activityIndicatorView.color = .lightGray
            activityIndicatorView.hidesWhenStopped = true
            
            self.tableFooterView = activityIndicatorView
            return activityIndicatorView
        }
        else {
            return activityIndicatorView
        }
    }
    
    func addLoading(_ indexPath:IndexPath, closure: @escaping (() -> Void)){
        if let lastVisibleIndexPath = self.indexPathsForVisibleRows?.last {
            if indexPath == lastVisibleIndexPath && indexPath.row == self.numberOfRows(inSection: 0) - 1 {
                DispatchQueue.main.async() {
                    self.indicatorView().startAnimating()
                    closure()
                }
            }
        }
    }
    
    func stopLoading() {
        if self.tableFooterView != nil {
            self.indicatorView().stopAnimating()
            self.tableFooterView = nil
        }
        else {
            self.tableFooterView = nil
        }
    }
}
