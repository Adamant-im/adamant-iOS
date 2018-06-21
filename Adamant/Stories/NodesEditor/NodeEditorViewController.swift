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
		static let testInProgressMessage = NSLocalizedString("NodesEditor.TestingInProgressMessage", comment: "NodesEditor: Testing in progress")
		static func testFailedMessage(reason: String) -> String {
			return String.localizedStringWithFormat(NSLocalizedString("NodesEditor.TestingFailedMessageFormat", comment: "NodesEditor: Testing failed message format. %@ for failure reason."), reason)
		}

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
		case `protocol`, port, url
		case testButton, deleteButton
		
		var localized: String {
			switch self {
			case .protocol: return "Protocol"
			case .port: return "Port"
			case .url: return "URL"
			case .testButton: return "Test"
			case .deleteButton: return "Delete node"
			}
		}
		
		var placeholder: String? {
			switch self {
			case .protocol: return ""
			case .port: return "port"
			case .url: return "ip/url"
			case .testButton: return nil
			case .deleteButton: return nil
			}
		}
		
		var tag: String {
			switch self {
			case .protocol: return "prtcl"
			case .port: return "prt"
			case .url: return "url"
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
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let node = node {
			self.navigationItem.title = node.url
		}
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		
		// MARK: - Node properties
		form +++ Section()
			
		// URL
		<<< TextRow() {
			$0.title = Rows.url.localized
			$0.tag = Rows.url.tag
			$0.placeholder = Rows.url.placeholder
			
			$0.value = node?.url
		}
			
		// Port
		<<< IntRow() {
			$0.title = Rows.port.localized
			$0.tag = Rows.port.tag
			$0.placeholder = Rows.port.placeholder
			
			$0.value = node?.port
		}
		
		// Protocol
		<<< PickerInlineRow<NodeProtocol>() {
			$0.title = Rows.protocol.localized
			$0.tag = Rows.protocol.tag
			$0.value = node?.protocol ?? NodeProtocol.https
			$0.options = [.https, .http]
		}.onExpandInlineRow({ (_, _, inlineRow) in
			inlineRow.cell.height = { 100 }
		})
		
		
		// MARK: - Buttons
		
		+++ Section()
		<<< ButtonRow() {
			$0.title = Rows.testButton.localized
			$0.tag = Rows.testButton.tag
		}.cellSetup({ (cell, row) in
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
			cell.textLabel?.textColor = UIColor.adamantPrimary
		}).cellUpdate({ (cell, _) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		}).onCellSelection({ [weak self] (_, _) in
			self?.testNode()
		})
		
		if node != nil {
			form +++ Section()
			<<< ButtonRow() {
				$0.title = Rows.deleteButton.localized
				$0.tag = Rows.deleteButton.tag
			}.cellSetup({ (cell, row) in
				cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
				cell.textLabel?.textColor = UIColor.adamantPrimary
			}).cellUpdate({ (cell, _) in
				cell.textLabel?.textColor = UIColor.adamantPrimary
			}).onCellSelection({ [weak self] (_, _) in
				self?.deleteNode()
			})
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
	func testNode() {
		var components = URLComponents()
		
		// Host
		if let row: TextRow = form.rowBy(tag: Rows.url.tag), let host = row.value {
			components.host = host
		}
		
		// Scheme
		if let row = form.rowBy(tag: Rows.protocol.tag), let pr = row.baseValue as? NodeProtocol {
			components.scheme = pr.rawValue
		} else {
			components.scheme = "https"
		}
		
		// Port
		if let row: IntRow = form.rowBy(tag: Rows.port.tag), let port = row.value {
			components.port = port
		}
		
		let url: URL
		do {
			url = try components.asURL()
		} catch {
			return
		}
		
		dialogService.showProgress(withMessage: String.adamantLocalized.nodesEditor.testInProgressMessage, userInteractionEnable: false)
		apiService.getNodeVersion(url: url) { [weak self] result in
			defer {
				self?.dialogService.dismissProgress()
			}
			
			switch result {
			case .success(_):
				break
				
			case .failure(let error):
				self?.dialogService.showWarning(withMessage: String.adamantLocalized.nodesEditor.testFailedMessage(reason: error.localized))
			}
		}
	}
	
	@objc func done() {
		guard let row: TextRow = form.rowBy(tag: Rows.url.tag), let rawUrl = row.value else {
			didCallDelegate = true
			delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .cancel)
			return
		}
		
		let url = rawUrl.trimmingCharacters(in: .whitespaces)
		
		let prot: NodeProtocol
		if let row: PickerRow<NodeProtocol> = form.rowBy(tag: Rows.protocol.tag), let pr = row.value {
			prot = pr
		} else {
			prot = .https
		}
		
		let port: Int?
		if let row: IntRow = form.rowBy(tag: Rows.port.tag), let p = row.value {
			port = p
		} else {
			port = nil
		}
		
		let node = Node(protocol: prot, url: url, port: port)
		
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
		didCallDelegate = false
		
		if let node = node, let tag = nodeTag {
			delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .delete(node: node, tag: tag))
		} else {
			delegate?.nodeEditorViewController(self, didFinishEditingWithResult: .cancel)
		}
	}
}
