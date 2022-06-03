//
//  HeaderReusableView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import MessageKit

class HeaderReusableView: MessageReusableView {
    // MARK: - Private Properties
    static private let insets = UIEdgeInsets(top: 12, left: 80, bottom: 12, right: 80)

    private var spinner = UIActivityIndicatorView(style: .gray)
    
    // MARK: - Public Methods
    static var height: CGFloat {
        return insets.top + insets.bottom + 27
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        createUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createUI()
    }

    /// Setup the receiver with text.
    ///
    /// - Parameter text: The text to be displayed.
    func setupLoadAnimating() {
        spinner.startAnimating()
    }

    func stopLoadAnimating() {
        spinner.stopAnimating()
    }
    
    override func prepareForReuse() {
        spinner.stopAnimating()
    }

    // MARK: - Private Methods
    private func createUI() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
}
