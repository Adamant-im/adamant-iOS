//
//  AMenuRowCell.swift
//
//
//  Created by Stanislav Jelezoglo on 26.07.2023.
//

import UIKit
import SnapKit

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
    
    private var lineColor: UIColor {
        let colorWhiteTheme  = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.8)
        let colorDarkTheme   = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.8)
        return .returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
    }
    
    private var selectColor: UIColor {
        let colorWhiteTheme  = UIColor.black.withAlphaComponent(0.10)
        let colorDarkTheme   = UIColor.white.withAlphaComponent(0.13)
        return .returnColorByTheme(colorWhiteTheme: colorWhiteTheme, colorDarkTheme: colorDarkTheme)
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
            lineView.backgroundColor = lineColor
        case .bottom:
            lineView.backgroundColor = .clear
        }
    }
    
    func select() {
        guard let rowBackgroundColor = rowBackgroundColor else {
            return
        }
        
        backgroundDarkeningView.backgroundColor = selectColor
        backgroundColorView.backgroundColor = rowBackgroundColor.withAlphaComponent(0.3)
    }
    
    func deselect() {
        backgroundDarkeningView.backgroundColor = .clear
        backgroundColorView.backgroundColor = rowBackgroundColor
    }
}
