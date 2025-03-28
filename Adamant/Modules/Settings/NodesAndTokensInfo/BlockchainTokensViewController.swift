//
//  BlockchainTokensViewController.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 28.03.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import AdamantWalletsKit
import UIKit

final class BlockchainsTokensViewController: UIViewController {
    private lazy var tableView: UITableView = .init(frame: view.bounds)
    private var coinsData: [CoinInfoDTO]
    private let dialogService: DialogService?
    
    init(coinsData: [CoinInfoDTO], title: String, dialogService: DialogService?) {
        self.coinsData = coinsData.sorted(by: { $0.symbol < $1.symbol })
        self.dialogService = dialogService
        super.init(nibName: nil, bundle: nil)
        self.title = "Tokens in \(title)"
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
}

extension BlockchainsTokensViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        coinsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = coinsData[indexPath.row].symbol.uppercased()
        cell.contentConfiguration = config
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = coinsData[indexPath.row]
        navigationController?.pushViewController(CoinInfoDTOViewController(coinInfo: model, dialogService: dialogService), animated: true)
    }
}
