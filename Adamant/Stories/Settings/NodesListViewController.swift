//
//  NodesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

// MARK: - SecuredStore keys
extension StoreKey {
    struct nodesList {
        static let userNodes = "nodesList.userNodes"
    }
}

// MARK: - Localization
extension String.adamantLocalized {
    struct nodesList {
        
        static let nodesListButton = NSLocalizedString("NodesList.NodesList", comment: "NodesList: Button label")
        static let title = NSLocalizedString("NodesList.Title", comment: "NodesList: scene title")
        static let saved = NSLocalizedString("NodesList.Saved", comment: "NodesList: 'Saved' message")
        static let unableToSave = NSLocalizedString("NodesList.UnableToSave", comment: "NodesList: 'Unable To Save' message")
        static let addNewNode = NSLocalizedString("NodesList.AddNewNode", comment: "NodesList: 'Add new node' button lable")
        static let nodeUrl = NSLocalizedString("NodesList.NodeUrl", comment: "NodesList: 'Node url' plaseholder")
        
        private init() {}
    }
}

class NodesListViewController: FormViewController {
    
    // MARK: Dependencies
    var dialogService: DialogService!
    var securedStore: SecuredStore!
    var apiService: ApiService!
    
    // MARK: Lifetime
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = String.adamantLocalized.nodesList.title
        navigationOptions = .Disabled
        
        if self.navigationController?.viewControllers.count == 1 {
            let cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(NodesListViewController.close))
            
            self.navigationItem.setLeftBarButton(cancelBtn, animated: false)
        }
        
        form +++
            MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                               header: String.adamantLocalized.nodesList.title,
                               footer: "") {
                                $0.tag = "nodes"
                                $0.addButtonProvider = { section in
                                    return ButtonRow(){
                                        $0.title = String.adamantLocalized.nodesList.addNewNode
                                    }
                                }
                                
                                $0.multivaluedRowToInsertAt = { index in
                                    return TextRow() {
                                        $0.placeholder = String.adamantLocalized.nodesList.nodeUrl
                                    }
                                }
                                
                                var serverUrls = AdamantResources.servers
                                if let usersNodesString = self.securedStore.get(StoreKey.nodesList.userNodes), let usersNodes = AdamantUtilities.toArray(text: usersNodesString) {
                                    serverUrls = usersNodes
                                }
                                
                                for serverUrl in serverUrls {
                                    $0 <<< TextRow() {
                                        $0.value = serverUrl
                                        $0.placeholder = String.adamantLocalized.nodesList.nodeUrl
                                    }
                                }
        }
        
        form +++ Section()
            <<< ButtonRow() {
                $0.title = String.adamantLocalized.alert.save
                }.cellSetup({ (cell, _) in
                    cell.selectionStyle = .gray
                }).onCellSelection({ [weak self] (_, _) in
                    self?.save()
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
    
    func save() {
        self.dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        let values = self.form.values()
        if let nodes = values["nodes"] as? [String] {
            
            if let jsonNodesList = AdamantUtilities.json(from:nodes) {
                self.securedStore.set(jsonNodesList, for: StoreKey.nodesList.userNodes)
                print("\(jsonNodesList)")
            } else {
                self.dialogService.showError(withMessage: String.adamantLocalized.nodesList.unableToSave, error: nil)
                return
            }
            self.apiService.updateServersList(servers: nodes)
            
            self.dialogService.showSuccess(withMessage: String.adamantLocalized.nodesList.saved)
            self.dialogService.dismissProgress()
            self.close()
        } else {
            self.dialogService.dismissProgress()
            self.dialogService.showError(withMessage: String.adamantLocalized.nodesList.unableToSave, error: nil)
        }
    }
}
