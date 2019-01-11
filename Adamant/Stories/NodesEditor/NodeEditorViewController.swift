//
//  NodeEditorViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

// MARK: - Localization
extension String.adamantLocalized {
	struct nodesEditor {
		static let newNodeTitle = NSLocalizedString("NodesEditor.NewNodeTitle", comment: "NodesEditor: New node scene title")
		static let deleteNodeAlert = NSLocalizedString("NodesEditor.DeleteNodeAlert", comment: "NodesEditor: Delete node confirmation message")
		static let failedToBuildURL = NSLocalizedString("NodesEditor.FailedToBuildURL", comment: "NodesEditor: Failed to build URL alert")
		
		static let testInProgressMessage = NSLocalizedString("NodesEditor.TestingInProgressMessage", comment: "NodesEditor: Testing in progress")
		static let testPassed = NSLocalizedString("NodesEditor.Passed", comment: "NodesEditor: test 'Passed' message")

		private init() {}
	}
}

// MARK: - Helpers
enum NodeEditorResult {
	case new(node: Node)
	case done(node: Node, tag: String)
	case cancel
	case delete(node: Node, tag: String)
}

protocol NodeEditorDelegate: class {
	func nodeEditorViewController(_ editor: NodeEditorViewController, didFinishEditingWithResult result: NodeEditorResult)
}

// MARK: - NodeEditorViewController
class NodeEditorViewController: FormViewController {
	// MARK: - Rows
	
	private enum Rows {
		// Node properties
		case host, port, scheme
		
		// Buttons
		case testButton, deleteButton
		
		var localized: String {
			switch self {
			case .scheme: return NSLocalizedString("NodesEditor.SchemeRow", comment: "NodesEditor: Scheme row")
			case .port: return NSLocalizedString("NodesEditor.PortRow", comment: "NodesEditor: Port row")
			case .host: return NSLocalizedString("NodesEditor.HostRow", comment: "NodesEditor: Host row")
			case .testButton: return NSLocalizedString("NodesEditor.TestButton", comment: "NodesEditor: Test button")
			case .deleteButton: return NSLocalizedString("NodesEditor.DeleteNodeButton", comment: "NodesEditor: Delete node button")
			}
		}
		
		var placeholder: String? {
			switch self {
			case .host: return NSLocalizedString("NodesEditor.HostRow.Placeholder", comment: "NodesEditor: Host row placeholder")
			case .port, .scheme, .testButton, .deleteButton: return nil
			}
		}
		
		var tag: String {
			switch self {
			case .scheme: return "prtcl"
			case .port: return "prt"
			case .host: return "url"
			case .testButton: return "test"
			case .deleteButton: return "delete"
			}
		}
	}
	
	
	// MARK: - Dependencies
	var dialogService: DialogService!
	var apiService: ApiService!
	
	
	// MARK: - Properties
	var node: Node?
	var nodeTag: String?
	
	weak var delegate: NodeEditorDelegate?
	private var didCallDelegate: Bool = false
	
    override var customNavigationAccessoryView: (UIView & NavigationAccessory)? {
        let accessory = NavigationAccessoryView()
        accessory.tintColor = UIColor.adamant.primary
        return accessory
    }
    
	// MARK: Test state
	enum TestState {
		case notTested, failed, passed
		
		var localized: String? {
			switch self {
			case .notTested: return nil
			case .failed: return NSLocalizedString("NodesEditor.NodeTestFailed", comment: "NodesEditor: Test failed")
			case .passed: return NSLocalizedString("NodesEditor.NodeTestPassed", comment: "NodesEditor: Test passed")
			}
		}
		
		fileprivate var accessoryType: UITableViewCell.AccessoryType {
			switch self {
			case .notTested, .failed: return .disclosureIndicator
			case .passed: return .checkmark
			}
		}
	}
	
	private (set) var testState: TestState = .notTested {
		didSet {
			guard testState != oldValue, let row = form.rowBy(tag: Rows.testButton.tag) else {
				return
			}
			
			let type = testState.accessoryType
			let value = testState.localized
			
			if Thread.isMainThread {
				row.baseCell.accessoryType = type
				row.baseValue = value
				row.updateCell()
			} else {
				DispatchQueue.main.async {
					row.baseValue = value
					row.updateCell()
					row.baseCell.accessoryType = type
				}
			}
		}
	}
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.styles = ["baseTable"]
        navigationController?.navigationBar.style = "baseNavigationBar"
        view.style = "primaryBackground,primaryTint"
		
		if let node = node {
			self.navigationItem.title = node.host
		} else {
			self.navigationItem.title = String.adamantLocalized.nodesEditor.newNodeTitle
		}
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		
		// MARK: - Node properties
		form +++ Section()
			
		// URL
		<<< TextRow() {
			$0.title = Rows.host.localized
			$0.tag = Rows.host.tag
			$0.placeholder = Rows.host.placeholder
			
			$0.value = node?.host
			}.onChange({ [weak self] (_) in
				self?.testState = .notTested
            }).cellUpdate { (cell, _) in
                cell.style = "secondaryBackground"
                cell.textLabel?.style = "primaryText"
                cell.textField?.style = "primaryText"
            }
			
		// Port
		<<< IntRow() {
			$0.title = Rows.port.localized
			$0.tag = Rows.port.tag
			
			if let node = node {
				$0.value = node.port
				$0.placeholder = String(node.scheme.defaultPort)
			} else {
				$0.placeholder = String(URLScheme.default.defaultPort)
			}
		}.onChange({ [weak self] (_) in
			self?.testState = .notTested
        }).cellUpdate { (cell, _) in
            cell.style = "secondaryBackground"
            cell.textLabel?.style = "primaryText"
            cell.textField?.style = "input"
        }
		
		// Scheme
		<<< PickerInlineRow<URLScheme>() {
			$0.title = Rows.scheme.localized
			$0.tag = Rows.scheme.tag
			$0.value = node?.scheme ?? URLScheme.default
			$0.options = [.https, .http]
		}.onExpandInlineRow({ (cell, _, inlineRow) in
			inlineRow.cell.height = { 100 }
            inlineRow.cell.style = "secondaryBackground,primaryText"
		}).onChange({ [weak self] row in
			self?.testState = .notTested
			
			if let portRow: IntRow = self?.form.rowBy(tag: Rows.port.tag) {
				if let scheme = row.value {
					portRow.placeholder = String(scheme.defaultPort)
				} else {
					portRow.placeholder = String(URLScheme.default.defaultPort)
				}
				
				portRow.updateCell()
			}
        }).cellUpdate { (cell, _) in
            cell.style = "secondaryBackground"
            cell.textLabel?.style = "primaryText"
            cell.detailTextLabel?.style = "primaryText"
        }
		
		
		// MARK: - Buttons
		
		+++ Section()
		
		// Test
		<<< LabelRow() {
			$0.title = Rows.testButton.localized
			$0.tag = Rows.testButton.tag
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
            cell.style = "baseTableCell,secondaryBackground"
            cell.textLabel?.style = "primaryText"
            cell.detailTextLabel?.style = "primaryText"
		}.onCellSelection { [weak self] (_, _) in
			self?.testNode()
		}
		
		// Delete
		if node != nil {
			form +++ Section()
			<<< ButtonRow() {
				$0.title = Rows.deleteButton.localized
				$0.tag = Rows.deleteButton.tag
			}.cellUpdate { (cell, _) in
                cell.style = "baseTableCell,secondaryBackground"
                cell.textLabel?.style = "primaryText"
			}.onCellSelection { [weak self] (_, _) in
				self?.deleteNode()
			}
		}
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didCallDelegate {
			done()
		}
	}
}


// MARK: - Actions
extension NodeEditorViewController {
	func testNode(completion: ((Bool) -> Void)? = nil) {
		var components = URLComponents()
		
		// Host
		if let row: TextRow = form.rowBy(tag: Rows.host.tag), let host = row.value {
			components.host = host
		}
		
		// Scheme
		let scheme: URLScheme
		if let row = form.rowBy(tag: Rows.scheme.tag), let value = row.baseValue as? URLScheme {
			scheme = value
		} else {
			scheme = URLScheme.default
		}
		components.scheme = scheme.rawValue
		
		// Port
		if let row: IntRow = form.rowBy(tag: Rows.port.tag), let port = row.value {
			components.port = port
		} else {
			components.port = scheme.defaultPort
		}
		
		let url: URL
		do {
			url = try components.asURL()
		} catch {
			testState = .failed
			dialogService.showWarning(withMessage: String.adamantLocalized.nodesEditor.failedToBuildURL)
			return
		}
		
		dialogService.showProgress(withMessage: String.adamantLocalized.nodesEditor.testInProgressMessage, userInteractionEnable: false)
		apiService.getNodeVersion(url: url) { result in
			switch result {
			case .success(_):
				self.dialogService.dismissProgress()
				self.testState = .passed
				completion?(true)
				
			case .failure(let error):
				self.dialogService.showWarning(withMessage: error.localized)
				self.testState = .failed
				completion?(false)
			}
		}
	}
	
	@objc func done() {
		switch testState {
		case .notTested, .failed:
			testNode { success in
				if success {
					self.saveNode()
				}
			}
			
		case .passed:
			saveNode()
		}
	}
	
	private func saveNode() {
		guard let row: TextRow = form.rowBy(tag: Rows.host.tag), let rawUrl = row.value else {
			didCallDelegate = true
			delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .cancel)
			return
		}
		
		let host = rawUrl.trimmingCharacters(in: .whitespaces)
		
		let scheme: URLScheme
		if let row = form.rowBy(tag: Rows.scheme.tag), let value = row.baseValue as? URLScheme {
			scheme = value
		} else {
			scheme = URLScheme.default
		}
		
		let port: Int?
		if let row: IntRow = form.rowBy(tag: Rows.port.tag), let p = row.value {
			port = p
		} else {
			port = nil
		}
		
		let node = Node(scheme: scheme, host: host, port: port)
		
		let result: NodeEditorResult
		if self.node != nil, let tag = nodeTag {
			result = .done(node: node, tag: tag)
		} else {
			result = .new(node: node)
		}
		
		didCallDelegate = true
		delegate?.nodeEditorViewController(self, didFinishEditingWithResult: result)
	}
	
	@objc func cancel() {
		didCallDelegate = true
		delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .cancel)
	}
	
	func deleteNode() {
		let alert = UIAlertController(title: String.adamantLocalized.nodesEditor.deleteNodeAlert, message: nil, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.delete, style: .destructive, handler: { _ in
            self.didCallDelegate = true
			
			if let node = self.node, let tag = self.nodeTag {
				self.delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .delete(node: node, tag: tag))
			} else {
				self.delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .cancel)
			}
		}))
		
		present(alert, animated: true, completion: nil)
	}
}
