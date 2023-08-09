//
//  UIListView.swift
//
//
//  Created by Andrey Golubenko on 09.08.2023.
//

import UIKit
import Combine

open class UIListView<
    Item: UIListItemModel
>: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {
    private let itemsSubject = CurrentValueSubject<[Item], Never>(.init())
    private var subscription: AnyCancellable?
    
    @MainActor open var items: [Item] {
        get { itemsSubject.value }
        set { itemsSubject.value = newValue }
    }
    
    override open var delegate: UICollectionViewDelegate? {
        get { super.delegate }
        set { assertionFailure("\(Self.self) is delegate itself") }
    }
    
    override open var dataSource: UICollectionViewDataSource? {
        get { super.dataSource }
        set { assertionFailure("\(Self.self) is dataSource itself") }
    }
    
    public init(layout: FlowLayout = .init()) {
        super.init(frame: .zero, collectionViewLayout: layout)
        configure()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    open func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        items.count
    }
    
    open func collectionView(
        _: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let viewType = items[safe: indexPath.item]?.viewType else { return .init() }
        return configureCell(viewType, indexPath: indexPath) ?? .init()
    }
    
    open func collectionView(
        _: UICollectionView,
        _: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionViewLayout.collectionViewContentSize.width
        
        return .init(
            width: width,
            height: items[safe: indexPath.item]?.viewModel.height(width: width) ?? .zero
        )
    }
}

private extension UIListView {
    func configure() {
        delegate = self
        dataSource = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        subscription = itemsSubject
            .map { items in items.map { String(describing: $0.viewType) } }
            .removeDuplicates()
            .sink { [weak self] _ in self?.reloadData() }
    }
    
    func configureCell<View: UIListItemView>(
        _: View.Type,
        indexPath: IndexPath
    ) -> UICollectionViewCell? {
        register(Cell<View>.self, forCellWithReuseIdentifier: .init(describing: Cell<View>.self))
        
        let cell = dequeueReusableCell(
            withReuseIdentifier: .init(describing: Cell<View>.self),
            for: indexPath
        ) as? Cell<View>
        
        let publisher = itemsSubject.compactMap { items in
            items[safe: indexPath.item]?.viewModel as? View.Model
        }
        
        cell?.subscribe(publisher: publisher, collectionViewLayout: collectionViewLayout)
        return cell
    }
}
