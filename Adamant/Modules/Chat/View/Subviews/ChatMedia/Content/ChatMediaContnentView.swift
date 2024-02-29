//
//  ChatMediaContnentView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SnapKit
import UIKit
import CommonKit

final class ChatMediaContentView: UIView {
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ChatFileTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private lazy var dataSource = TransactionsDiffableDataSource(tableView: tableView, cellProvider: makeCell)

    var model: Model = .default {
        didSet {
            guard oldValue != model else { return }
            update()
        }
    }
    
    var actionHandler: (ChatAction) -> Void = { _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatMediaContentView {
    func configure() {
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
    }
    
    func update() {
        let list = model.files
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatFile>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(list)
        snapshot.reconfigureItems(list)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func makeCell(
        tableView: UITableView,
        indexPath: IndexPath,
        fileModel: ChatFile
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatFileTableViewCell
        cell.model = fileModel
        cell.backgroundView?.backgroundColor = .clear
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.buttonActionHandler = { [actionHandler, fileModel, model] in
            actionHandler(
                .processFile(
                    file: fileModel,
                    isFromCurrentSender: model.isFromCurrentSender
                )
            )
        }
        return cell
    }
}

extension ChatMediaContentView: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        imageSize
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        print("did select\(indexPath.row)")
    }
}

extension ChatMediaContentView.Model {
    func height() -> CGFloat {
        imageSize * CGFloat(files.count)
    }
}

private let nameFont = UIFont.systemFont(ofSize: 15)
private let sizeFont = UIFont.systemFont(ofSize: 13)
private let imageSize: CGFloat = 90
private typealias TransactionsDiffableDataSource = UITableViewDiffableDataSource<Int, ChatFile>
private let cellIdentifier = "cell"
