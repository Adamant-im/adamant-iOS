//
//  TokensAndCoinsViewController.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 28.03.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import AdamantWalletsKit
import CommonKit
import SnapKit
import UIKit

final class TokensAndCoinsViewController: UIViewController {
    private lazy var tableView: UITableView = .init(frame: view.bounds)

    private var chainsData: [AnyBlockchain] = []
    private var coinsData: [CoinInfoDTO] = []
    private let dialogService: DialogService?

    init(dialogService: DialogService?) {
        self.dialogService = dialogService
        super.init(nibName: nil, bundle: nil)
        title = "Coins and Tokens storage"
        setupDataSource()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupDataSource() {
        guard let coinsData = CoinInfoProvider.storage?.getCoinsAndChains() else { return }
        self.chainsData = coinsData.chains.map { $0.key }.sorted(by: { $0.rawValue < $1.rawValue })
        self.coinsData = coinsData.coins.sorted(by: { $0.key < $1.key }).map({ $0.value })
    }

    private func setupViews() {
        view.addSubview(tableView)
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
}

extension TokensAndCoinsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            chainsData.count
        } else {
            coinsData.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            cellForChain(at: indexPath, in: tableView)
        } else {
            cellForCoin(at: indexPath, in: tableView)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            "Blockchains"
        } else {
            "Coins"
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let viewController = viewControllerFor(indexPath: indexPath)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func viewControllerFor(indexPath: IndexPath) -> UIViewController {
        if indexPath.section == 0 {
            let chain = chainsData[indexPath.row]
            if let coinsForChain = CoinInfoProvider.storage?[chain] {
                return BlockchainsTokensViewController(coinsData: coinsForChain.map { $0.value }, title: chain.rawValue, dialogService: dialogService)
            } else {
                return UIViewController()
            }
        } else {
            let model = coinsData[indexPath.row]
            return CoinInfoDTOViewController(coinInfo: model, dialogService: dialogService)
        }
    }

    private func cellForChain(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = chainsData[indexPath.row].rawValue
        cell.contentConfiguration = config
        return cell
    }

    private func cellForCoin(at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = coinsData[indexPath.row].symbol.uppercased()
        cell.contentConfiguration = config
        return cell
    }
}
