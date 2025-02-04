import UIKit

final class EdgeInsetTextField: UITextField {
    var caretInset: CGFloat = .zero
    
    public override func caretRect(for position: UITextPosition) -> CGRect {
        super.caretRect(for: position).offsetBy(dx: -caretInset, dy: 0)
    }
}
