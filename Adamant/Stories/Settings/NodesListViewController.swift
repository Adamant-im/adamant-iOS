//
//  NodesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

import UIKit
import Eureka

class NodesListViewController: FormViewController {
    
    // MARK: Dependencies
    var dialogService: DialogService!
    
    
    // MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = String.adamantLocalized.settings.title
        navigationOptions = .Disabled
        
        if self.navigationController?.viewControllers.count == 1 {
            let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(NodesListViewController.close))
            
            self.navigationItem.setLeftBarButton(cancelBtn, animated: false)
        }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: "List of nodes",
                               footer: "") {
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.title = "Add New Node"
                                    }
                                }
                                $0.multivaluedRowToInsertAt = { index in
                                    return URLRow() {
                                        $0.placeholder = "Node Url"
//                                        $0.add(rule: RuleRequired())
//                                        $0.add(rule: RuleEmail())
                                    }
                                }
                                
                                for serverUrl in AdamantResources.servers {
                                    $0 <<< URLRow() {
                                        $0.value = URL(string: serverUrl)
                                        $0.placeholder = "Node Url"
                                    }
                                }
        }
        
        form +++ Section()
            <<< ButtonRow() {
                $0.title = "Save"
                $0.tag = "save"
                }.cellSetup({ (cell, _) in
                    cell.selectionStyle = .gray
                }).onCellSelection({ [weak self] (_, _) in
                    self?.close()
                }).cellSetup({ (cell, row) in
                    cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
                    cell.textLabel?.textColor = UIColor.adamantPrimary
                }).cellUpdate({ (cell, _) in
                    cell.textLabel?.textColor = UIColor.adamantPrimary
                })
        
        
    }
    
    @objc func close() {
        if self.navigationController?.viewControllers.count == 1 {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
