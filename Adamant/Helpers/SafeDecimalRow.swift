//
//  SafeDecimalRow.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import Eureka

/// A decimal row without empty hint on MacOS
final class SafeDecimalRow: _SafeDecimalRow, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class _SafeDecimalRow: FieldRow<SafeDecimalCell> {
    required init(tag: String?) {
        super.init(tag: tag)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        formatter = numberFormatter
    }
}

final class SafeDecimalCell: CustomFieldCell<Double, EdgeInsetTextField>, CellType {
    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setup() {
        super.setup()
        textField.autocorrectionType = .no
        textField.setPopupKeyboardType(.decimalPad)
    }
}

extension CustomFieldCell {
    /// Sets hugging priorities to make text field to take as much space as possible
    func adjustHuggingPriority() {
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel?.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
