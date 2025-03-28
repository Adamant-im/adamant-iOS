//
//  CoinInfoDTOViewController.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 28.03.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import AdamantWalletsKit
import UIKit
import CommonKit

private protocol AnyPrimitive: Sendable {}

extension Int: AnyPrimitive {}
extension String: AnyPrimitive {}
extension Double: AnyPrimitive {}
extension Bool: AnyPrimitive {}

final class CoinInfoDTOViewController: UIViewController {
    private var coinInfoSerialized: [String: String] = [:]
    private var keys: [String] = []
    private lazy var tableView: UITableView = .init(frame: view.bounds)
    private let dialogService: DialogService?
    
    init(coinInfo: CoinInfoDTO, dialogService: DialogService?) {
        self.dialogService = dialogService
        super.init(nibName: nil, bundle: nil)
        setDataSource(for: coinInfo)
        title = "Description for \(coinInfo.symbol.uppercased())"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    private func setDataSource(for coinInfo: CoinInfoDTO) {
        guard let data = try? JSONEncoder().encode(coinInfo) else { return }

        func flatten(value: Any, prefix: String) {
            let mirror = Mirror(reflecting: value)

            if let primitiveValue = value as? AnyPrimitive {
                coinInfoSerialized[prefix] = "\(primitiveValue)"
                return
            }

            if let stringConvertible = value as? CustomStringConvertible {
                coinInfoSerialized[prefix] = stringConvertible.description
                return
            }

            switch mirror.displayStyle {
            case .optional:
                if let firstChild = mirror.children.first {
                    flatten(value: firstChild.value, prefix: prefix)
                } else {
                    coinInfoSerialized[prefix] = "nil"
                }

            case .struct, .class:
                for child in mirror.children {
                    guard let propertyName = child.label else { continue }
                    flatten(value: child.value, prefix: "\(prefix).\(propertyName)")
                }

            case .enum:
                coinInfoSerialized[prefix] = "\(value)"

            case .collection:
                var index = 0
                for item in mirror.children {
                    flatten(value: item.value, prefix: "\(prefix)[\(index)]")
                    index += 1
                }

            case .dictionary:
                for (key, val) in mirror.children {
                    guard let key else { continue }
                    flatten(value: val, prefix: "\(prefix).\(key)")
                }

            default:
                let stringValue = "\(value)"
                coinInfoSerialized[prefix] = stringValue.isEmpty ? "empty" : stringValue
            }
        }
        flatten(value: coinInfo, prefix: coinInfo.symbol.uppercased())
        keys = coinInfoSerialized.map { $0.key }.sorted { $0 < $1 }
    }
}

extension CoinInfoDTOViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        let key = keys[indexPath.row]
        config.text = key
        config.secondaryText = coinInfoSerialized[key]
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath),
           let value = (cell.contentConfiguration as? UIListContentConfiguration)?.secondaryText {
            UIPasteboard.general.string = value
            dialogService?.showToastMessage("Value copied")
        }
    }
}

