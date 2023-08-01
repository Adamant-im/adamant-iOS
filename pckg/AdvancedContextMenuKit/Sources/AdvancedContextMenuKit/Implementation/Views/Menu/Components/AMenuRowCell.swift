//
//  AMenuRowCell.swift
//
//
//  Created by Stanislav Jelezoglo on 26.07.2023.
//

import UIKit
import SnapKit
import CommonKit

final class AMenuRowCell: UITableViewCell {    
    lazy var titleLabel = UILabel()
    lazy var iconImage = UIImageView(image: nil)
    lazy var backgroundColorView = UIView()
    lazy var backgroundDarkeningView = UIView()
    lazy var lineView = UIView()
    
    // MARK: Proprieties
    
    enum RowPosition {
        case top
        case bottom
        case other
    }
    
    private var rowBackgroundColor: UIColor?
    
    // MARK: Init
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        contentView.addSubview(backgroundColorView)
        contentView.addSubview(backgroundDarkeningView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(iconImage)
        contentView.addSubview(lineView)
        
        backgroundColorView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        backgroundDarkeningView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(20)
        }
        
        iconImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(25)
        }
        
        lineView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    func configure(
        with menuItem: AMenuItem,
        accentColor: UIColor?,
        backgroundColor: UIColor?,
        font: UIFont?,
        rowPosition: RowPosition
    ) {
        selectionStyle = .none
        
        titleLabel.text = menuItem.name
        iconImage.image = menuItem.iconImage
        backgroundColorView.backgroundColor = backgroundColor
        
        menuItem.style.configure(
            titleLabel: titleLabel,
            icon: iconImage,
            backgroundView: backgroundColorView,
            menuAccentColor: accentColor,
            menuFont: font
        )
        
        rowBackgroundColor = backgroundColorView.backgroundColor
        backgroundColorView.backgroundColor = rowBackgroundColor
        
        switch rowPosition {
        case .top, .other:
            lineView.backgroundColor = .adamant.contextMenuLineColor
        case .bottom:
            lineView.backgroundColor = .clear
        }
    }
    
    func select() {
        guard let rowBackgroundColor = rowBackgroundColor else {
            return
        }
        
        backgroundDarkeningView.backgroundColor = .adamant.contextMenuSelectColor
        backgroundColorView.backgroundColor = rowBackgroundColor.withAlphaComponent(0.3)
    }
    
    func deselect() {
        backgroundDarkeningView.backgroundColor = .clear
        backgroundColorView.backgroundColor = rowBackgroundColor
    }
}
