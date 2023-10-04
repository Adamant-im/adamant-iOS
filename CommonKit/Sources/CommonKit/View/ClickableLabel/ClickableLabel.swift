//
//  ClickableLabel.swift
//
//
//  Created by Andrey Golubenko on 06.08.2023.
//

import UIKit

public final class ClickableLabel: UIView {
    public typealias TapAction = (Item) -> Void
    
    public var tapAction: TapAction?
    
    public var attributedText = NSAttributedString() {
        didSet { updateAttributedText(attributedText) }
    }
    
    public var numberOfLines: Int = .zero {
        didSet { updateNumberOfLines(numberOfLines) }
    }

    private let detector: NSDataDetector?
    private var recognizer: UIGestureRecognizer?
    private var clickableItems = [NSTextCheckingResult]()

    private lazy var textContainer = makeTextContainer(lineBreakMode: label.lineBreakMode)
    private lazy var layoutManager = makeLayoutManager(textContainer: textContainer)
    private lazy var textStorage = makeTextStorage(layoutManager: layoutManager)
    
    private let label = UILabel()
    
    public override var intrinsicContentSize: CGSize {
        label.intrinsicContentSize
    }

    public init(clickableTypes: Set<ItemType>, numberOfLines: Int) {
        detector = try? .init(types: clickableTypes.textCheckingResultType.rawValue)
        assert(detector != nil, "NSDataDetector making error")
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        detector = nil
        assertionFailure("init(coder:) has not been implemented")
        super.init(coder: coder)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
        textContainer.size = label.bounds.size
    }
}

private extension ClickableLabel {
    func configure() {
        addSubview(label)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        updateAttributedText(attributedText)
        updateNumberOfLines(numberOfLines)
    }
    
    func updateAttributedText(_ attributedText: NSAttributedString) {
        let attributedText = parsedText(attributedText)
        label.attributedText = attributedText
        textStorage.setAttributedString(attributedText)
        invalidateIntrinsicContentSize()
    }
    
    func updateNumberOfLines(_ numberOfLines: Int) {
        label.numberOfLines = numberOfLines
        textContainer.maximumNumberOfLines = numberOfLines
        invalidateIntrinsicContentSize()
    }
    
    @objc func onTap(recognizer: UIGestureRecognizer) {
        guard
            let index = stringIndex(at: recognizer.location(in: label)),
            let textCheckingItem = clickableItems.first(where: { $0.range.contains(index) }),
            let item = textCheckingItem.clickableLabelItem
        else { return }
        
        tapAction?(item)
    }
    
    func parsedText(_ text: NSAttributedString) -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: text)
        var result = [NSTextCheckingResult]()
        defer { clickableItems = result }
        
        let range = NSRange(location: .zero, length: text.length)
        result = detector?.matches(in: text.string, options: [], range: range) ?? .init()
        colorFoundMatches(checkingResults: result, string: text)
        
        // Enumerate NSAttributedString NSLinks and append ranges
        
        text.enumerateAttribute(.link, in: range, options: []) { value, range, _ in
            guard let url = value as? URL else { return }
            result.append(.linkCheckingResult(range: range, url: url))
        }
        
        return text
    }
    
    func stringIndex(at location: CGPoint) -> Int? {
        guard textStorage.length > .zero else { return nil }
        
        let index = layoutManager.glyphIndex(for: location, in: textContainer)
        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: nil)
        
        return lineRect.contains(location)
            ? layoutManager.characterIndexForGlyph(at: index)
            : nil
    }
    
    func colorFoundMatches(checkingResults: [NSTextCheckingResult], string: NSMutableAttributedString) {
        let colorAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.adamant.active
        ]
        
        checkingResults.forEach { result in
            guard result.resultType == .link else { return }
            string.addAttributes(colorAttributes, range: result.range)
        }
    }
}

private func makeTextContainer(lineBreakMode: NSLineBreakMode) -> NSTextContainer {
    let textContainer = NSTextContainer()
    textContainer.lineFragmentPadding = .zero
    textContainer.lineBreakMode = lineBreakMode
    return textContainer
}

private func makeLayoutManager(textContainer: NSTextContainer) -> NSLayoutManager {
    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)
    return layoutManager
}

private func makeTextStorage(layoutManager: NSLayoutManager) -> NSTextStorage {
    let textStorage = NSTextStorage()
    textStorage.addLayoutManager(layoutManager)
    return textStorage
}
