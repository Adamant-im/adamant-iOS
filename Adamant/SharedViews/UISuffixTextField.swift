//
//  UISuffixTextField.swift
//  Adamant
//
//  Created by Anton Boyarkin on 09/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

public final class SuffixTextRow: FieldRow<SuffixTextCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
    
    public override func updateCell() {
        super.updateCell()
    }
}

public class SuffixTextCell: _FieldCell<String>, CellType {
    
    public var suffix: String?
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initSetup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initSetup()
    }
    
    func initSetup() {
        self.textField.removeFromSuperview()
        let textField = UISuffixTextField()
        self.textField = textField
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)
    }
    
    open override func setup() {
        super.setup()
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .sentences
        textField.keyboardType = .default
    }
    
    public override func update() {
        super.update()
        (self.textField as! UISuffixTextField).suffix = suffix
        self.textField.setNeedsDisplay()
    }
    
    public override func textFieldDidChange(_ textField: UITextField) {
        super.textFieldDidChange(textField)
        self.textField.setNeedsDisplay()
    }
}

class UISuffixTextField: UITextField {
    
    open var suffix: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        if let suffix = suffix {
            let color = (textColor ?? UIColor.black)
            color.setFill()
            var x: CGFloat = 0
            let font = self.font ?? UIFont.systemFont(ofSize: 14)
            
            if let text = text {
                let textSize = text.size(withAttributes: [.font : font])
                
                if textAlignment == NSTextAlignment.center {
                    x = (frame.size.width / 2) + textSize.width
                } else {
                    x = textSize.width
                }
            }
            
            let suffixSize = suffix.size(withAttributes: [.font : font])
            suffix.draw(in: CGRect(x: x, y: 0, width: suffixSize.width, height: suffixSize.height), withAttributes: [.font : font, .foregroundColor: color])
        }
    }
}
