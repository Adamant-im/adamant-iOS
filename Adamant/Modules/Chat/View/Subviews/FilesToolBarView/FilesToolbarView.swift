//
//  FilesToolbarView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 17.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import FilesStorageKit
import CommonKit

final class FilesToolbarView: UIView {
    private lazy var collectionView: UICollectionView = {
        let flow = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = 5
        flow.minimumLineSpacing = 5
        flow.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flow)
        collectionView.register(FilesToolbarCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: FilesToolbarCollectionViewCell.self)
        )
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.addSubview(collectionView)

        collectionView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        return view
    }()
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(
            UIImage(systemName: "xmark")?.withTintColor(.adamant.alert),
            for: .normal
        )
        btn.addTarget(self, action: #selector(didTapCloseBtn), for: .touchUpInside)
        
        btn.snp.makeConstraints { make in
            make.size.equalTo(30)
        }
        return btn
    }()
    
    private lazy var horizontalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [containerView, closeBtn])
        stack.axis = .horizontal
        stack.spacing = horizontalStackSpacing
        return stack
    }()
    
    // MARK: Proprieties
    
    private var data: [FileResult] = []
    var closeAction: (() -> Void)?
    var updatedDataAction: (([FileResult]) -> Void)?
    var openFileAction: ((FileResult) -> Void)?
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    func configure() {
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(verticalInsets)
            $0.horizontalEdges.equalToSuperview().inset(horizontalInsets)
        }
    }
    
    // MARK: Actions
    
    @objc private func didTapCloseBtn() {
        closeAction?()
    }
    
    private func removeFile(at index: Int) {
        data.remove(at: index)
        collectionView.reloadData()
        updatedDataAction?(data)
    }
}

extension FilesToolbarView {
    func update(_ data: [FileResult]) {
        self.data = data
        collectionView.reloadData()
        Task {
            collectionView.scrollToItem(
                at: .init(row: data.count - 1, section: .zero),
                at: .right,
                animated: true
            )
        }
    }
}

extension FilesToolbarView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        data.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: FilesToolbarCollectionViewCell.self),
            for: indexPath
        ) as? FilesToolbarCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.update(data[indexPath.row], tag: indexPath.row)
        cell.buttonActionHandler = { [weak self] index in
            self?.removeFile(at: index)
        }
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        .init(
            width: self.frame.height - itemOffset,
            height: self.frame.height - itemOffset
        )
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        openFileAction?(data[indexPath.row])
    }
}

private let horizontalStackSpacing: CGFloat = 25
private let verticalInsets: CGFloat = 8
private let horizontalInsets: CGFloat = 12
private let itemOffset: CGFloat = 10
