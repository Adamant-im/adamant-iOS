//
//  NodesListViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

// MARK: - Localization
extension String.adamantLocalized {
    struct nodesList {
        static let title = NSLocalizedString("NodesList.Title", comment: "NodesList: scene title")
        static let nodesListButton = NSLocalizedString("NodesList.NodesList", comment: "NodesList: Button label")
        
        static let defaultNodesWasLoaded = NSLocalizedString("NodeList.DefaultNodesLoaded", comment: "NodeList: Inform that default nodes was loaded, if user deleted all nodes")
        
        static let resetAlertTitle = NSLocalizedString("NodesList.ResetNodeListAlert", comment: "NodesList: Reset nodes alert title")
        
        private init() {}
    }
}

// MARK: - NodesListViewController
class NodesListViewController: FormViewController {
    // Rows & Sections
    
    private enum Sections {
        case nodes
        case buttons
        case reset
        
        var tag: String {
            switch self {
            case .nodes: return "nds"
            case .buttons: return "bttns"
            case .reset: return "reset"
            }
        }
    }
    
    private enum Rows {
        case addNode
        case save
        case reset
        
        var localized: String {
            switch self {
            case .addNode:
                return NSLocalizedString("NodesList.AddNewNode", comment: "NodesList: 'Add new node' button lable")
                
            case .save:
                return String.adamantLocalized.alert.save
                
            case .reset:
                return NSLocalizedString("NodesList.ResetButton", comment: "NodesList: 'Reset' button")
            }
        }
    }
    
    // MARK: Dependencies
    var dialogService: DialogService!
    var securedStore: SecuredStore!
    var apiService: ApiService!
    var router: Router!
    var nodesSource: NodesSource!
    
    // Properties
    
    private var nodes = [Node]()
    private var didResetNodesOnDissapear = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String.adamantLocalized.nodesList.title
        navigationOptions = .Disabled
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        
        if splitViewController == nil, navigationController?.viewControllers.count == 1 {
            let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(NodesListViewController.close))
            navigationItem.rightBarButtonItem = done
        }
        
        // MARK: Nodes
        
        let section = Section {
            $0.tag = Sections.nodes.tag
        }
        
        nodes = nodesSource.nodes
        nodes.forEach { section <<< createRowFor(node: $0, tag: generateRandomTag()) }
        
        form +++ section
        
        // MARK: Buttons
        
        +++ Section {
            $0.tag = Sections.buttons.tag
        }
        
        // Add node
        <<< ButtonRow {
            $0.title = Rows.addNode.localized
        }.cellSetup { (cell, _) in
            cell.selectionStyle = .gray
        }.onCellSelection { [weak self] (_, _) in
            self?.createNewNode()
        }
            
        // MARK: Reset
            
        +++ Section {
            $0.tag = Sections.reset.tag
        }
            
        <<< ButtonRow {
            $0.title = Rows.reset.localized
        }.onCellSelection { [weak self] (_, _) in
            self?.resetToDefault()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let top = navigationController?.topViewController, top == self && presentedViewController == nil && nodes.count == 0 {
            didResetNodesOnDissapear = true
            loadDefaultNodes(showAlert: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if navigationController == nil && nodes.count == 0 && !didResetNodesOnDissapear {
            loadDefaultNodes(showAlert: true)
        }
    }
    
    /*
    Ячейки, удаляемые в режиме редактирования, никак не обрабатываются
    @objc func editModeStart() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editModeStop))
        tableView.setEditing(true, animated: true)
    }
    
    @objc func editModeStop() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editModeStart))
        tableView.setEditing(false, animated: true)
    }
    */
}

// MARK: - Manipulating node list
extension NodesListViewController {
    func createNewNode() {
        presentEditor(forNode: nil, tag: nil)
    }
    
    func removeNode(at index: Int) {
        nodes.remove(at: index)
        
        if let section = form.sectionBy(tag: Sections.nodes.tag) {
            section.remove(at: index)
        }
    }
    
    func editNode(_ node: Node, tag: String) {
        presentEditor(forNode: node, tag: tag)
    }
    
    @objc func close() {
        if self.navigationController?.viewControllers.count == 1 {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func resetToDefault(silent: Bool = false) {
        if silent {
            let nodes = nodesSource.defaultNodes
            setNodes(nodes: nodes)
            return
        }
        
        let alert = UIAlertController(title: String.adamantLocalized.nodesList.resetAlertTitle, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Rows.reset.localized, style: .destructive, handler: { [weak self] (_) in
            guard let nodes = self?.nodesSource.defaultNodes else {
                return
            }
            
            self?.setNodes(nodes: nodes)
            self?.nodesSource.saveNodes()
        }))
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
    
    func setNodes(nodes: [Node]) {
        guard let section = form.sectionBy(tag: Sections.nodes.tag) else {
            return
        }
        
        section.removeAll()
        
        for node in nodes {
            let row = createRowFor(node: node, tag: generateRandomTag())
            section.append(row)
        }
        
        self.nodes = nodes
        nodesSource.nodes = nodes
    }
}

// MARK: - NodeEditorDelegate
extension NodesListViewController: NodeEditorDelegate {
    func nodeEditorViewController(_ editor: NodeEditorViewController, didFinishEditingWithResult result: NodeEditorResult) {
        switch result {
        case .new(let node):
            guard let section = form.sectionBy(tag: Sections.nodes.tag) else {
                return
            }
            
            nodes.append(node)
            
            let row = createRowFor(node: node, tag: generateRandomTag())
            section <<< row
            
            saveNodes()
            
        case .done(let node, let tag):
            guard let row: NodeRow = form.rowBy(tag: tag) else {
                return
            }
            
            if let prevNode = row.value, let index = nodes.firstIndex(of: prevNode) {
                nodes.remove(at: index)
            }
            
            nodes.append(node)
            row.value = node
            
            saveNodes()
            
        case .delete(let editorNode, let tag):
            guard let row: NodeRow = form.rowBy(tag: tag), let node = row.value else {
                return
            }
            
            if let index = nodes.firstIndex(of: node) {
                nodes.remove(at: index)
            } else if let index = nodes.firstIndex(of: editorNode) {
                nodes.remove(at:index)
            }
            
            if let section = form.sectionBy(tag: Sections.nodes.tag), let index = section.firstIndex(of: row) {
                section.remove(at: index)
            }
            
            saveNodes()
            
        case .cancel:
            break
        }
        
        DispatchQueue.main.async {
            if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
                self.navigationController?.popToViewController(self, animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

// MARK: - Loading & Saving nodes
extension NodesListViewController {
    func saveNodes() {
        guard nodes.count > 0 else {
            return
        }
        
        nodesSource.nodes = nodes
        nodesSource.saveNodes()
    }
    
    func loadDefaultNodes(showAlert: Bool) {
        let nodes = nodesSource.defaultNodes
        nodesSource.nodes = nodes
        nodesSource.saveNodes()
        
        if showAlert {
            dialogService.showSuccess(withMessage: String.adamantLocalized.nodesList.defaultNodesWasLoaded)
        }
    }
}

// MARK: - Tools
extension NodesListViewController {
    private func createRowFor(node: Node, tag: String) -> BaseRow {
        let row = NodeRow {
            $0.value = node
            $0.tag = tag
            
            let deleteAction = SwipeAction(style: .destructive, title: "Delete") { [weak self] (_, row, completionHandler) in
                if let node = row.baseValue as? Node, let index = self?.nodes.firstIndex(of: node) {
                    self?.nodes.remove(at: index)
                    self?.saveNodes()
                }
                completionHandler?(true)
            }
            
            $0.trailingSwipe.actions = [deleteAction]
            
            if #available(iOS 11,*) {
                $0.trailingSwipe.performsFirstActionWithFullSwipe = true
            }
        }.cellUpdate { (cell, _) in
            if let label = cell.textLabel {
                label.textColor = UIColor.adamant.primary
            }
            
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, row) in
            guard let node = row.value, let tag = row.tag else {
                return
            }
            
            self?.editNode(node, tag: tag)
        }
        
        return row
    }
    
    private func presentEditor(forNode node: Node?, tag: String?) {
        guard let editor = router.get(scene: AdamantScene.NodesEditor.nodeEditor) as? NodeEditorViewController else {
            fatalError("Failed to get editor")
        }
        
        editor.delegate = self
        editor.node = node
        editor.nodeTag = tag
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            self.navigationController?.pushViewController(editor, animated: true)
        } else {
            let navigator = UINavigationController(rootViewController: editor)
            navigator.modalPresentationStyle = .overFullScreen
            present(navigator, animated: true, completion: nil)
        }
    }
    
    private func generateRandomTag() -> String {
        let capacity = 6
        var nums: [UInt32] = []
        nums.reserveCapacity(capacity)
        
        for _ in 0...capacity {
            nums.append(arc4random_uniform(10))
        }
        
        return nums.compactMap { String($0) }.joined()
    }
}
