//
//  ContributeViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SwiftUI

class ContributeViewController: FormViewController {
    // MARK: Rows
    enum Rows {
        case crashlytics
        
        var tag: String {
            switch self {
            case .crashlytics: return "crashlystic"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .crashlytics: return #imageLiteral(resourceName: "row_logo")
            }
        }
        
        var localized: String {
            switch self {
            case .crashlytics: return NSLocalizedString("Contribute.Section.Crashlytics", comment: "Contribute scene: 'Crashlytics' section title.")
            }
        }
        
    }
    
    // MARK: - Dependencies
    
    var crashlyticsService: CrashlyticsService
    
    // MARK: - Init
    
    init(crashlyticsService: CrashlyticsService) {
        self.crashlyticsService = crashlyticsService
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = AccountViewController.Rows.contribute.localized
        
        let section = Section()
        
        let crashlysticRow = SwitchRow {
            $0.tag = Rows.crashlytics.tag
            $0.title = Rows.crashlytics.localized
            $0.cell.imageView?.image = Rows.crashlytics.image
            $0.value = crashlyticsService.isCrashlyticsEnabled()
        }.cellUpdate { (cell, _) in
            cell.switchControl.onTintColor = UIColor.adamant.active
        }.onChange { [weak self] row in
            guard let enabled = row.value else {
                return
            }
            
            self?.crashlyticsService.setCrashlyticsEnabled(enabled)
        }
        
        section.append(crashlysticRow)
        
        form.append(section)
        
        setColors()
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
}
