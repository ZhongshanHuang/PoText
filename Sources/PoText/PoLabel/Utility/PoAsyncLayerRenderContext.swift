import UIKit

final class PoAsyncLayerRenderContext: @unchecked Sendable {
    let text: NSAttributedString
    let container: TextContainer
    let verticalAlignment: TextVerticalAlignment
    let contentsNeedFade: Bool
    let fadeForAsync: Bool
    let textContainerInsets: UIEdgeInsets
    let shouldCommitLayout: Bool
    
    private var resolvedLayout: TextLayout?
    private let layoutLock = NSLock()

    /// The resolved layout is shared by the drawing task and the main-thread
    /// attachment callbacks. Access is serialized because the context is
    /// intentionally sendable across those execution domains.
    var layout: TextLayout? {
        layoutLock.lock()
        defer { layoutLock.unlock() }
        return resolvedLayout
    }

    var hasRenderableContent: Bool {
        !text.isEmpty || layout != nil
    }
    
    init(text: NSAttributedString,
         container: TextContainer,
         verticalAlignment: TextVerticalAlignment,
         contentsNeedFade: Bool,
         fadeForAsync: Bool,
         textContainerInsets: UIEdgeInsets,
         layout: TextLayout? = nil,
         shouldCommitLayout: Bool = false) {
        self.text = text.isEmpty ? NSAttributedString() : (text.copy() as? NSAttributedString ?? text)
        self.container = layout == nil && !text.isEmpty ? container.snapshot() : container
        self.verticalAlignment = verticalAlignment
        self.contentsNeedFade = contentsNeedFade
        self.fadeForAsync = fadeForAsync
        self.textContainerInsets = textContainerInsets
        self.resolvedLayout = layout
        self.shouldCommitLayout = shouldCommitLayout
    }
    
    func draw(in context: CGContext, size: CGSize) {
        guard let layout = resolveLayout() else { return }
        let point = drawingPoint(for: size, textBoundingSize: layout.textBoundingSize)
        layout.draw(in: context, at: point, size: size)
    }
    
    func drawingPoint(for size: CGSize) -> CGPoint {
        let boundingSize = layout?.textBoundingSize ?? .zero
        return drawingPoint(for: size, textBoundingSize: boundingSize)
    }
    
    @discardableResult
    func resolveLayout() -> TextLayout? {
        layoutLock.lock()
        defer { layoutLock.unlock() }
        if let resolvedLayout { return resolvedLayout }
        guard !text.isEmpty else { return nil }
        let layout = TextLayout(attributedString: text, container: container)
        resolvedLayout = layout
        return layout
    }
    
    private func drawingPoint(for size: CGSize, textBoundingSize: CGSize) -> CGPoint {
        var point = CGPoint(x: textContainerInsets.left, y: 0)
        switch verticalAlignment {
        case .center:
            point.y = (size.height - textBoundingSize.height) * 0.5 + (textContainerInsets.top - textContainerInsets.bottom) / 2
        case .bottom:
            point.y = (size.height - textBoundingSize.height) - textContainerInsets.bottom
        case .top:
            point.y = textContainerInsets.top
        }
        return point.pixelRound
    }
}
