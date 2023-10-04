//
//  UITableView+Extension.swift
//  
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit

public extension UITableView {
    func register<T: UITableViewCell>(_ cellClass: T.Type) {
        register(cellClass, forCellReuseIdentifier: .init(describing: T.self))
    }
    
    func dequeueReusableCell<T: UITableViewCell>(
        _ cellClass: T.Type,
        for indexPath: IndexPath
    ) -> T {
        guard
            let cell = dequeueReusableCell(
                withIdentifier: .init(describing: T.self),
                for: indexPath
            ) as? T
        else {
            fatalError("Unable to dequeue \(String(describing: cellClass)) with reuseId of \(String(describing: T.self))")
        }
        
        return cell
    }
}
