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
    
    public var tapAction: TapAction = { _ in }
    
    public var attributedText: NSAttributedString = .init() {
        didSet {
            guard oldValue != attributedText else { return }
            updateAttributedText()
        }
    }
    
    public var numberOfLines: Int = .zero {
        didSet {
            guard oldValue != numberOfLines else { return }
            updateNumberOfLines()
        }
    }
    
    public var colors: [ItemType: UIColor] = .init() {
        didSet {
            guard oldValue != colors else { return }
            updateColors()
        }
    }
    
    private let detector: NSDataDetector?
    private var recognizer: UIGestureRecognizer?
    private var clickableItems = [NSTextCheckingResult]()

    private lazy var textContainer = makeTextContainer(lineBreakMode: label.lineBreakMode)
    private lazy var layoutManager = makeLayoutManager(textContainer: textContainer)
    private lazy var textStorage = makeTextStorage(layoutManager: layoutManager)
    
    private let label = UILabel()

    public init(clickableTypes: Set<ItemType>) {
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
        textContainer.size = label.bounds.size
    }
}

private extension ClickableLabel {
    func configure() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        updateAttributedText()
        updateNumberOfLines()
        
        addSubview(label)
        label.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
    
    func updateAttributedText() {
        parseText(attributedText)
        updateColors()
    }
    
    func updateColors() {
        let string = NSMutableAttributedString(attributedString: attributedText)
        colorText(string)
        label.attributedText = string
        textStorage.setAttributedString(string)
    }
    
    func updateNumberOfLines() {
        label.numberOfLines = numberOfLines
        textContainer.maximumNumberOfLines = numberOfLines
    }
    
    @objc func onTap(recognizer: UIGestureRecognizer) {
        guard
            let index = stringIndex(at: recognizer.location(in: label)),
            let textCheckingItem = clickableItems.first(where: { $0.range.contains(index) })
        else { return }
        
        textCheckingItem.clickableLabelItems.forEach(tapAction)
    }
    
    func stringIndex(at location: CGPoint) -> Int? {
        guard textStorage.length > .zero else { return nil }
        
        let index = layoutManager.glyphIndex(for: location, in: textContainer)
        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: nil)
        
        return lineRect.contains(location)
            ? layoutManager.characterIndexForGlyph(at: index)
            : nil
    }
    
    func parseText(_ text: NSAttributedString) {
        let range = NSRange(location: .zero, length: text.length)
        clickableItems = detector?.matches(in: text.string, options: [], range: range) ?? .init()
        
        // Enumerate NSAttributedString NSLinks and append ranges
        
        text.enumerateAttribute(.link, in: range, options: []) { value, range, _ in
            guard let url = value as? URL else { return }
            clickableItems.append(.linkCheckingResult(range: range, url: url))
        }
    }
    
    func colorText(_ text: NSMutableAttributedString) {
        clickableItems.forEach { checkingResult in
            guard
                let itemType = checkingResult.clickableLabelItems.first?.type,
                let color = colors[itemType]
            else { return }
            
            text.addAttributes(
                [.foregroundColor: color],
                range: checkingResult.range
            )
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
