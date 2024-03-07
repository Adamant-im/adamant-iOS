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
        collectionView.register(FilesToolbarCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        let colorView = UIView()
        colorView.backgroundColor = .adamant.active
        
        view.addSubview(colorView)
        view.addSubview(collectionView)

        colorView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(2)
        }
        collectionView.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(colorView.snp.trailing).offset(5)
        }
        return view
    }()
    
    private lazy var iconView: UIView = {
        let view = UIView()
        view.addSubview(iconIV)
        iconIV.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        view.snp.makeConstraints { make in
            make.width.equalTo(27)
        }
        return view
    }()
    
    private var iconIV: UIImageView = {
        let iv = UIImageView(
            image: UIImage(
                systemName: "square.and.arrow.up"
            )?.withTintColor(.adamant.active)
        )
        
        iv.tintColor = .adamant.active
        iv.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(27)
        }
        
        return iv
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
        let stack = UIStackView(arrangedSubviews: [iconView, containerView, closeBtn])
        stack.axis = .horizontal
        stack.spacing = horizontalStackSpacing
        return stack
    }()
    
    // MARK: Proprieties
    
    private var data: [FileResult] = []
    var closeAction: (() -> Void)?
    var updatedDataAction: (([FileResult]) -> Void)?
    
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
            $0.top.bottom.equalToSuperview().inset(verticalInsets)
            $0.leading.trailing.equalToSuperview().inset(15)
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
    }
}

extension FilesToolbarView: UICollectionViewDelegate, UICollectionViewDataSource {
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
            withReuseIdentifier: "cell",
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
}

private let horizontalStackSpacing: CGFloat = 25
private let verticalInsets: CGFloat = 8
