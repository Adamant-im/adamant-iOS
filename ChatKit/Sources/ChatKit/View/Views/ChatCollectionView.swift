//
//  ChatCollectionView.swift
//  Adamant
//
//  Created by Andrew G on 16.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit

private typealias DateCell = ChatCellWrapper<ChatDateView>
private typealias LoaderCell = ChatCellWrapper<ChatLoaderView>
private typealias MessageCell = ChatCellWrapper<ChatMessageView>
private typealias TransactionCell = ChatCellWrapper<ChatTransactionView>
private typealias InternalChatItem = HashableIDWrapper<ChatItemModel>
private typealias ChatDiffableDataSource = UITableViewDiffableDataSource<Int, InternalChatItem>

final class ChatCollectionView: UIView, Modelable {
    var modelStorage = [HashableIDWrapper<ChatItemModel>]() {
        didSet { update() }
    }
    
    private lazy var tableView = makeTableView(delegate: self)
    private lazy var dataSource = ChatDiffableDataSource(tableView: tableView, cellProvider: makeCell)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func safeAreaInsetsDidChange() {
        tableView.contentInset = .init(
            top: safeAreaInsets.bottom,
            left: safeAreaInsets.left,
            bottom: safeAreaInsets.top,
            right: safeAreaInsets.right
        )
    }
}

extension ChatCollectionView: UITableViewDelegate {
    func scrollViewDidScroll(_: UIScrollView) {}
}

private extension ChatCollectionView {
    func configure() {
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        update()
    }
    
    func update() {
        let model: [InternalChatItem] = model.reversed()
        var snapshot = NSDiffableDataSourceSnapshot<Int, InternalChatItem>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(model)
        snapshot.reconfigureItems(model)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

private func makeCell(
    tableView: UITableView,
    indexPath: IndexPath,
    model: InternalChatItem
) -> UITableViewCell {
    switch model.value {
    case .loader:
        return tableView.dequeueReusableCell(LoaderCell.self, for: indexPath)
    case let .date(model):
        let cell = tableView.dequeueReusableCell(DateCell.self, for: indexPath)
        cell.wrappedView.model = model
        return cell
    case let .message(model):
        let cell = tableView.dequeueReusableCell(MessageCell.self, for: indexPath)
        cell.wrappedView.model = model
        return cell
    case let .transaction(model):
        let cell = tableView.dequeueReusableCell(TransactionCell.self, for: indexPath)
        cell.wrappedView.model = model
        return cell
    }
}

private func makeTableView(delegate: UITableViewDelegate) -> UITableView {
    let view = UITableView()
    view.delegate = delegate
    view.transform = CGAffineTransform(scaleX: 1, y: -1)
    view.rowHeight = UITableView.automaticDimension
    view.estimatedRowHeight = .leastNormalMagnitude
    view.contentInsetAdjustmentBehavior = .never
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    view.separatorStyle = .none
    view.register(DateCell.self)
    view.register(LoaderCell.self)
    view.register(MessageCell.self)
    view.register(TransactionCell.self)
    return view
}
