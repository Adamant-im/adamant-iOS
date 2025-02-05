import Eureka
import UIKit

// Copy of _FieldCell from Eureka with generic descendant of UITextField class
open class CustomFieldCell<T, TextFieldType: UITextField> : Cell<T>, UITextFieldDelegate, TextFieldCell where T: Equatable, T: InputTypeInitiable {

    weak var _textField: TextFieldType!
    public var textField: UITextField! {
        _textField
    }
    weak var titleLabel: UILabel?

    fileprivate var observingTitleText = false
    private var awakeFromNibCalled = false

    open var dynamicConstraints = [NSLayoutConstraint]()

    private var calculatedTitlePercentage: CGFloat = 0.7

    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        let textField = TextFieldType()
        self._textField = textField
        textField.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupTitleLabel()

        contentView.addSubview(titleLabel!)
        contentView.addSubview(textField)

        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let me = self else { return }
            guard me.observingTitleText else { return }
            me.titleLabel?.removeObserver(me, forKeyPath: "text")
            me.observingTitleText = false
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let me = self else { return }
            guard !me.observingTitleText else { return }
            me.titleLabel?.addObserver(me, forKeyPath: "text", options: [.new, .old], context: nil)
            me.observingTitleText = true
        }

        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.setupTitleLabel()
            self?.setNeedsUpdateConstraints()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        awakeFromNibCalled = true
    }

    deinit {
        textField?.delegate = nil
        textField?.removeTarget(self, action: nil, for: .allEvents)
        guard !awakeFromNibCalled else { return }
        if observingTitleText {
            titleLabel?.removeObserver(self, forKeyPath: "text")
        }
        imageView?.removeObserver(self, forKeyPath: "image")
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    open override func setup() {
        super.setup()
        selectionStyle = .none

        if !awakeFromNibCalled {
            titleLabel?.addObserver(self, forKeyPath: "text", options: [.new, .old], context: nil)
            observingTitleText = true
            imageView?.addObserver(self, forKeyPath: "image", options: [.new, .old], context: nil)
        }
        textField.addTarget(self, action: #selector(CustomFieldCell.textFieldDidChange(_:)), for: .editingChanged)

        if let titleLabel = titleLabel {
            // Make sure the title takes over most of the empty space so that the text field starts editing at the back.
            let priority = UILayoutPriority(rawValue: titleLabel.contentHuggingPriority(for: .horizontal).rawValue + 1)
            textField.setContentHuggingPriority(priority, for: .horizontal)
        }
    }

    open override func update() {
        super.update()
        detailTextLabel?.text = nil

        if !awakeFromNibCalled {
            if let title = row.title {
                switch row.cellStyle {
                case .subtitle:
                    textField.textAlignment = .left
                    textField.clearButtonMode = .whileEditing
                default:
                    textField.textAlignment = title.isEmpty ? .left : .right
                    textField.clearButtonMode = title.isEmpty ? .whileEditing : .never
                }
            } else {
                textField.textAlignment = .left
                textField.clearButtonMode = .whileEditing
            }
        } else {
            textLabel?.text = nil
            titleLabel?.text = row.title
            if #available(iOS 13.0, *) {
                titleLabel?.textColor = row.isDisabled ? .tertiaryLabel : .label
            } else {
                titleLabel?.textColor = row.isDisabled ? .gray : .black
            }
        }
        textField.delegate = self
        textField.text = row.displayValueFor?(row.value)
        textField.isEnabled = !row.isDisabled
        if #available(iOS 13.0, *) {
            textField.textColor = row.isDisabled ? .tertiaryLabel : .label
        } else {
            textField.textColor = row.isDisabled ? .gray : .black
        }
        textField.font = .preferredFont(forTextStyle: .body)
        if let placeholder = (row as? FieldRowConformance)?.placeholder {
            if let color = (row as? FieldRowConformance)?.placeholderColor {
                textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: color])
            } else {
                textField.placeholder = (row as? FieldRowConformance)?.placeholder
            }
        }
        if row.isHighlighted {
            titleLabel?.textColor = tintColor
        }
    }

    open override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && textField?.canBecomeFirstResponder == true
    }

    open override func cellBecomeFirstResponder(withDirection: Direction) -> Bool {
        return textField.becomeFirstResponder()
    }

    open override func cellResignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let obj = object as AnyObject?
        
        if let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKey.kindKey],
           ((obj === titleLabel && keyPathValue == "text") || (obj === imageView && keyPathValue == "image")) &&
            (changeType as? NSNumber)?.uintValue == NSKeyValueChange.setting.rawValue {
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }

    // MARK: Helpers

    open func customConstraints() {

        guard !awakeFromNibCalled else { return }
        contentView.removeConstraints(dynamicConstraints)
        dynamicConstraints = []

        switch row.cellStyle {
        case .subtitle:
            var views: [String: AnyObject] =  ["textField": textField]

            if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                views["titleLabel"] = titleLabel
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel]-3-[textField]-|",
                                                                     options: .alignAllLeading, metrics: nil, views: views)
                titleLabel.setContentHuggingPriority(
                    UILayoutPriority(textField.contentHuggingPriority(for: .vertical).rawValue + 1), for: .vertical)
                dynamicConstraints.append(NSLayoutConstraint(item: titleLabel, attribute: .centerX, relatedBy: .equal, toItem: textField, attribute: .centerX, multiplier: 1, constant: 0))
            } else {
                dynamicConstraints.append(NSLayoutConstraint(item: textField!, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0))
            }

            if let imageView = imageView, let _ = imageView.image {
                views["imageView"] = imageView
                if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[titleLabel]-|", options: [], metrics: nil, views: views)
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[textField]-|", options: [], metrics: nil, views: views)
                } else {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[textField]-|", options: [], metrics: nil, views: views)
                }
            } else {
                if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-|", options: [], metrics: nil, views: views)
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField]-|", options: [], metrics: nil, views: views)
                } else {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField]-|", options: .alignAllLeft, metrics: nil, views: views)
                }
            }

        default:
            var views: [String: AnyObject] =  ["textField": textField]
            dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[textField]-|", options: .alignAllLastBaseline, metrics: nil, views: views)
            
            if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                views["titleLabel"] = titleLabel
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel]-|", options: .alignAllLastBaseline, metrics: nil, views: views)
                dynamicConstraints.append(NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: textField, attribute: .centerY, multiplier: 1, constant: 0))
            }

            if let imageView = imageView, let _ = imageView.image {
                views["imageView"] = imageView
                if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[titleLabel]-[textField]-|", options: [], metrics: nil, views: views)
                    dynamicConstraints.append(NSLayoutConstraint(item: titleLabel,
                                                                 attribute: .width,
                                                                 relatedBy: (row as? FieldRowConformance)?.titlePercentage != nil ? .equal : .lessThanOrEqual,
                                                                 toItem: contentView,
                                                                 attribute: .width,
                                                                 multiplier: calculatedTitlePercentage,
                                                                 constant: 0.0))
                } else {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[textField]-|", options: [], metrics: nil, views: views)
                }
            } else {
                if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-[textField]-|", options: [], metrics: nil, views: views)
                    dynamicConstraints.append(NSLayoutConstraint(item: titleLabel,
                                                                 attribute: .width,
                                                                 relatedBy: (row as? FieldRowConformance)?.titlePercentage != nil ? .equal : .lessThanOrEqual,
                                                                 toItem: contentView,
                                                                 attribute: .width,
                                                                 multiplier: calculatedTitlePercentage,
                                                                 constant: 0.0))
                } else {
                    dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField]-|", options: .alignAllLeft, metrics: nil, views: views)
                }
            }
        }
        contentView.addConstraints(dynamicConstraints)
    }

    open override func updateConstraints() {
        customConstraints()
        super.updateConstraints()
    }

    @objc open func textFieldDidChange(_ textField: UITextField) {
 
        guard textField.markedTextRange == nil else { return }
        
        guard let textValue = textField.text else {
            row.value = nil
            return
        }
        guard let fieldRow = row as? FieldRowConformance, let formatter = fieldRow.formatter else {
            row.value = textValue.isEmpty ? nil : (T.init(string: textValue) ?? row.value)
            return
        }
        if fieldRow.useFormatterDuringInput {
            let unsafePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
            defer {
                unsafePointer.deallocate()
            }
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(unsafePointer)
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.pointee as? T
                guard var selStartPos = textField.selectedTextRange?.start else { return }
                let oldVal = textField.text
                textField.text = row.displayValueFor?(row.value)
                selStartPos = (formatter as? FormatterProtocol)?.getNewPosition(forPosition: selStartPos, inTextInput: textField, oldValue: oldVal, newValue: textField.text) ?? selStartPos
                textField.selectedTextRange = textField.textRange(from: selStartPos, to: selStartPos)
                return
            }
        } else {
            let unsafePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
            defer {
                unsafePointer.deallocate()
            }
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(unsafePointer)
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.pointee as? T
            } else {
                row.value = textValue.isEmpty ? nil : (T.init(string: textValue) ?? row.value)
            }
        }
    }

    // MARK: Helpers

    private func setupTitleLabel() {
        titleLabel = self.textLabel
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
    }

    private func displayValue(useFormatter: Bool) -> String? {
        guard let v = row.value else { return nil }
        if let formatter = (row as? FormatterConformance)?.formatter, useFormatter {
            return textField?.isFirstResponder == true ? formatter.editingString(for: v) : formatter.string(for: v)
        }
        return String(describing: v)
    }

    // MARK: TextFieldDelegate

    open func textFieldDidBeginEditing(_ textField: UITextField) {
        formViewController()?.beginEditing(of: self)
        formViewController()?.textInputDidBeginEditing(textField, cell: self)
        if let fieldRowConformance = row as? FormatterConformance, let _ = fieldRowConformance.formatter, fieldRowConformance.useFormatterOnDidBeginEditing ?? fieldRowConformance.useFormatterDuringInput {
            textField.text = displayValue(useFormatter: true)
        } else {
            textField.text = displayValue(useFormatter: false)
        }
    }

    open func textFieldDidEndEditing(_ textField: UITextField) {
        formViewController()?.endEditing(of: self)
        formViewController()?.textInputDidEndEditing(textField, cell: self)
        textFieldDidChange(textField)
        textField.text = displayValue(useFormatter: (row as? FormatterConformance)?.formatter != nil)
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldReturn(textField, cell: self) ?? true
    }

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return formViewController()?.textInput(textField, shouldChangeCharactersInRange:range, replacementString:string, cell: self) ?? true
    }

    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldBeginEditing(textField, cell: self) ?? true
    }

    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldClear(textField, cell: self) ?? true
    }

    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textField, cell: self) ?? true
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard let row = (row as? FieldRowConformance) else { return }
        defer {
            // As titleLabel is the textLabel, iOS may re-layout without updating constraints, for example:
            // swiping, showing alert or actionsheet from the same section.
            // thus we need forcing update to use customConstraints()
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
        guard let titlePercentage = row.titlePercentage else  { return }
        var targetTitleWidth = bounds.size.width * titlePercentage
        if let imageView = imageView, let _ = imageView.image, let titleLabel = titleLabel {
            var extraWidthToSubtract = titleLabel.frame.minX - imageView.frame.minX // Left-to-right interface layout
            if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
                extraWidthToSubtract = imageView.frame.maxX - titleLabel.frame.maxX
            }
            targetTitleWidth -= extraWidthToSubtract
        }
        calculatedTitlePercentage = targetTitleWidth / contentView.bounds.size.width
    }
}
