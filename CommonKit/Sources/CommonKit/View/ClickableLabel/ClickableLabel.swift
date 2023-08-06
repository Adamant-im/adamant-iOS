//
//  ClickableLabel.swift
//
//
//  Created by Andrey Golubenko on 06.08.2023.
//

import UIKit
import SnapKit

public final class ClickableLabel: UIView {
    public typealias TapAction = (Item) -> Void
    
    public var tapAction: TapAction?
    
    public var attributedText = NSAttributedString() {
        didSet { updateText(attributedText) }
    }

    private let detector: NSDataDetector?
    private var recognizer: UIGestureRecognizer?
    private var clickableItems = [NSTextCheckingResult]()

    private lazy var label = UILabel()
    private lazy var layoutManager = makeLayoutManager()
    private lazy var textContainer = makeTextContainer()
    private lazy var textStorage = makeTextStorage()

    public init(clickableTypes: Set<ItemType>, numberOfLines: Int) {
        detector = try? .init(types: clickableTypes.textCheckingResultType.rawValue)
        assert(detector != nil, "NSDataDetector making error")
        super.init(frame: .zero)
        label.numberOfLines = numberOfLines
        setupLayout()
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(recognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = label.bounds.size
    }
}

private extension ClickableLabel {
    @objc func onTap(recognizer: UIGestureRecognizer) {
        guard
            let index = stringIndex(at: recognizer.location(in: label)),
            let textCheckingItem = clickableItems.first(where: { $0.range.contains(index) }),
            let item = textCheckingItem.clickableLabelItem
        else { return }
        
        tapAction?(item)
    }
    
    func setupLayout() {
        addSubview(label)
        label.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func updateText(_ text: NSAttributedString) {
        label.attributedText = text
        textStorage.setAttributedString(text)
        parseText(text)
        invalidateIntrinsicContentSize()
    }
    
    func parseText(_ text: NSAttributedString) {
        var result = [NSTextCheckingResult]()
        defer { clickableItems = result }
        
        let range = NSRange(location: .zero, length: text.length)
        result = detector?.matches(in: text.string, options: [], range: range) ?? .init()
        
        // Enumerate NSAttributedString NSLinks and append ranges
        
        text.enumerateAttribute(.link, in: range, options: []) { value, range, _ in
            guard let url = value as? URL else { return }
            result.append(.linkCheckingResult(range: range, url: url))
        }
    }
    
    func stringIndex(at location: CGPoint) -> Int? {
        guard textStorage.length > .zero else { return nil }
        
        let index = layoutManager.glyphIndex(for: location, in: textContainer)
        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: nil)
        
        return lineRect.contains(location)
            ? layoutManager.characterIndexForGlyph(at: index)
            : nil
    }

    func makeLayoutManager() -> NSLayoutManager {
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        return layoutManager
    }

    func makeTextContainer() -> NSTextContainer {
        let textContainer = NSTextContainer()
        textContainer.lineFragmentPadding = .zero
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.size = label.bounds.size
        return textContainer
    }

    func makeTextStorage() -> NSTextStorage {
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        return textStorage
    }
}
