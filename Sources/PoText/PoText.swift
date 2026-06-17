import UIKit

public struct PoTextActionContext {
    public let label: PoLabel
    public let text: NSAttributedString?
    public let range: NSRange

    public var selectedText: NSAttributedString? {
        guard let text,
              range.location != NSNotFound,
              range.location >= 0,
              NSMaxRange(range) <= text.length else {
            return nil
        }
        return text.attributedSubstring(from: range)
    }

    public var selectedString: String? {
        selectedText?.string
    }

    public init(label: PoLabel, text: NSAttributedString?, range: NSRange) {
        self.label = label
        self.text = text
        self.range = range
    }
}

public typealias PoTextAction = (PoTextActionContext) -> Void

public enum PoTextStyleMergePolicy: Sendable {
    case keepLocal
    case overrideLocal
}

public struct PoTextStyle: @unchecked Sendable {
    private var container: PoAttributeContainer

    var attributeContainer: PoAttributeContainer {
        container
    }

    public var attributes: [NSAttributedString.Key: Any] {
        container.attributes
    }

    public init() {
        container = PoAttributeContainer()
    }

    public init(font: UIFont, color: UIColor? = nil) {
        container = PoAttributeContainer()
        container.font = font
        if let color {
            container.foregroundColor = color
        }
    }

    public init(_ attributes: [NSAttributedString.Key: Any]) {
        container = PoAttributeContainer(attributes)
    }

    init(_ container: PoAttributeContainer) {
        self.container = container
    }

    public func addingAttributes(_ attributes: [NSAttributedString.Key: Any]) -> Self {
        var new = self
        new.container.merge(PoAttributeContainer(attributes))
        return new
    }

    public func font(_ font: UIFont) -> Self {
        setting { $0.font = font }
    }

    public func color(_ color: UIColor) -> Self {
        foregroundColor(color)
    }

    public func foregroundColor(_ color: UIColor) -> Self {
        setting { $0.foregroundColor = color }
    }

    public func kern(_ kern: CGFloat) -> Self {
        setting { $0.kern = kern }
    }

    public func underline(_ style: NSUnderlineStyle = .single, color: UIColor? = nil) -> Self {
        setting {
            $0.underlineStyle = style
            if let color {
                $0.underlineStyleColor = color
            }
        }
    }

    public func strikethrough(_ style: NSUnderlineStyle = .single, color: UIColor? = nil) -> Self {
        setting {
            $0.strikethroughStyle = style
            if let color {
                $0.strikethroughColor = color
            }
        }
    }

    public func baselineOffset(_ offset: CGFloat) -> Self {
        setting { $0.baselineOffset = offset }
    }

    public func shadow(_ shadow: NSShadow) -> Self {
        setting { $0.shadow = shadow }
    }

    public func paragraphStyle(_ paragraphStyle: NSParagraphStyle) -> Self {
        setting { $0.paragraphStyle = paragraphStyle }
    }

    public func textBorder(_ border: TextBorder) -> Self {
        setting { $0.textBorder = border }
    }

    public func textBlockBorder(_ border: TextBorder) -> Self {
        setting { $0.textBlockBorder = border }
    }

    private func setting(_ update: (inout PoAttributeContainer) -> Void) -> Self {
        var new = self
        update(&new.container)
        return new
    }
}

public struct PoText: @unchecked Sendable {
    private let storage: NSMutableAttributedString

    public var attributedString: NSAttributedString {
        storage.copy() as? NSAttributedString ?? NSAttributedString()
    }

    public var mutableAttributedString: NSMutableAttributedString {
        NSMutableAttributedString(attributedString: storage)
    }

    public init(_ string: String) {
        storage = NSMutableAttributedString(string: string)
    }

    public init(_ attributedString: NSAttributedString) {
        storage = NSMutableAttributedString(attributedString: attributedString)
    }

    public init(style: PoTextStyle,
                mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                @PoTextBuilder _ builder: () -> NSAttributedString) {
        storage = NSMutableAttributedString(attributedString: builder())
        storage.po_applyStyle(style, mergePolicy: mergePolicy)
    }

    public init(_ string: String, style: PoTextStyle) {
        storage = NSMutableAttributedString(string: string)
        storage.po.addAttributes(style.attributes)
    }

    init(storage: NSMutableAttributedString) {
        self.storage = storage
    }

    public func style(_ style: PoTextStyle) -> Self {
        attributes(style.attributes)
    }

    func attributeContainer(_ container: PoAttributeContainer) -> Self {
        attributes(container.attributes)
    }

    public func attributes(_ attributes: [NSAttributedString.Key: Any]) -> Self {
        applying { $0.po.addAttributes(attributes) }
    }

    public func font(_ font: UIFont?) -> Self {
        applying { $0.po.font = font }
    }

    public func color(_ color: UIColor?) -> Self {
        foregroundColor(color)
    }

    public func foregroundColor(_ color: UIColor?) -> Self {
        applying { $0.po.foregroundColor = color }
    }

    public func kern(_ kern: CGFloat?) -> Self {
        applying { $0.po.kern = kern }
    }

    public func underline(_ style: NSUnderlineStyle = .single, color: UIColor? = nil) -> Self {
        applying {
            $0.po.underlineStyle = style
            if let color {
                $0.po.underlineColor = color
            }
        }
    }

    public func strikethrough(_ style: NSUnderlineStyle = .single, color: UIColor? = nil) -> Self {
        applying {
            $0.po.strikethroughStyle = style
            if let color {
                $0.po.strikethroughColor = color
            }
        }
    }

    public func stroke(width: CGFloat?, color: UIColor? = nil) -> Self {
        applying {
            $0.po.strokeWidth = width
            if let color {
                $0.po.strokeColor = color
            }
        }
    }

    public func shadow(_ shadow: NSShadow?) -> Self {
        applying { $0.po.shadow = shadow }
    }

    public func shadow(color: UIColor, offset: CGSize = .zero, blur: CGFloat = 0) -> Self {
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowOffset = offset
        shadow.shadowBlurRadius = blur
        return self.shadow(shadow)
    }

    public func baselineOffset(_ offset: CGFloat?) -> Self {
        applying { $0.po.baselineOffset = offset }
    }

    public func paragraphStyle(_ paragraphStyle: NSParagraphStyle?) -> Self {
        applying { $0.po.paragraphStyle = paragraphStyle }
    }

    public func lineSpacing(_ spacing: CGFloat) -> Self {
        applying { $0.po.lineSpacing = spacing }
    }

    public func alignment(_ alignment: NSTextAlignment) -> Self {
        applying { $0.po.alignment = alignment }
    }

    public func lineBreak(_ mode: NSLineBreakMode) -> Self {
        applying { $0.po.lineBreakMode = mode }
    }

    public func textBorder(_ border: TextBorder?) -> Self {
        applying { $0.po.textBorder = border }
    }

    public func textBlockBorder(_ border: TextBorder?) -> Self {
        applying { $0.po.textBlockBorder = border }
    }

    public func fill(_ color: UIColor,
                     cornerRadius: CGFloat = 3,
                     insets: UIEdgeInsets = UIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2),
                     shadow: TextShadow? = nil) -> Self {
        textBorder(TextBorder(fillColor: color,
                              cornerRadius: cornerRadius,
                              insets: insets,
                              shadow: shadow))
    }

    public func highlight(_ highlight: TextHighlight?) -> Self {
        applying { text in
            text.po.setTextHighlight(nil, range: text.allRange)
            text.po.setTextHighlight(highlight, range: text.allRange)
        }
    }

    public func onTap(highlightForegroundColor: UIColor? = nil,
                      highlightBackgroundColor: UIColor? = nil,
                      action: @escaping PoTextAction) -> Self {
        updatingHighlight(foregroundColor: highlightForegroundColor,
                          backgroundColor: highlightBackgroundColor) { highlight in
            highlight.tapAction = { label, text, range in
                action(PoTextActionContext(label: label, text: text, range: range))
            }
        }
    }

    public func onLongPress(highlightForegroundColor: UIColor? = nil,
                            highlightBackgroundColor: UIColor? = nil,
                            action: @escaping PoTextAction) -> Self {
        updatingHighlight(foregroundColor: highlightForegroundColor,
                          backgroundColor: highlightBackgroundColor) { highlight in
            highlight.longPressAction = { label, text, range in
                action(PoTextActionContext(label: label, text: text, range: range))
            }
        }
    }

    public static func link(_ string: String,
                            color: UIColor = .systemBlue,
                            isUnderlined: Bool = false,
                            highlightColor: UIColor? = nil,
                            action: @escaping PoTextAction) -> PoText {
        var text = PoText(string)
            .foregroundColor(color)
            .onTap(highlightBackgroundColor: highlightColor ?? color.withAlphaComponent(0.12),
                   action: action)
        if isUnderlined {
            text = text.underline(color: color)
        }
        return text
    }

    public static func attachment(_ content: TextAttachment.Content,
                                  size: CGSize? = nil,
                                  alignToFont font: UIFont = .systemFont(ofSize: 17),
                                  contentInsets: UIEdgeInsets = .zero,
                                  verticalAlignment: TextVerticalAlignment = .center,
                                  contentMode: UIView.ContentMode = .scaleAspectFit) -> PoText {
        PoText(NSAttributedString.po.attachmentString(with: content,
                                                      size: size,
                                                      alignToFont: font,
                                                      contentInsets: contentInsets,
                                                      verticalAlignment: verticalAlignment,
                                                      contentMode: contentMode))
    }

    public static func attachment(_ image: UIImage,
                                  size: CGSize? = nil,
                                  alignToFont font: UIFont = .systemFont(ofSize: 17),
                                  contentInsets: UIEdgeInsets = .zero,
                                  verticalAlignment: TextVerticalAlignment = .center,
                                  contentMode: UIView.ContentMode = .scaleAspectFit) -> PoText {
        attachment(.image(image),
                   size: size,
                   alignToFont: font,
                   contentInsets: contentInsets,
                   verticalAlignment: verticalAlignment,
                   contentMode: contentMode)
    }

    public static func attachment(_ view: UIView,
                                  size: CGSize? = nil,
                                  alignToFont font: UIFont = .systemFont(ofSize: 17),
                                  contentInsets: UIEdgeInsets = .zero,
                                  verticalAlignment: TextVerticalAlignment = .center,
                                  contentMode: UIView.ContentMode = .scaleAspectFit) -> PoText {
        attachment(.view(view),
                   size: size,
                   alignToFont: font,
                   contentInsets: contentInsets,
                   verticalAlignment: verticalAlignment,
                   contentMode: contentMode)
    }

    public static func attachment(_ layer: CALayer,
                                  size: CGSize? = nil,
                                  alignToFont font: UIFont = .systemFont(ofSize: 17),
                                  contentInsets: UIEdgeInsets = .zero,
                                  verticalAlignment: TextVerticalAlignment = .center,
                                  contentMode: UIView.ContentMode = .scaleAspectFit) -> PoText {
        attachment(.layer(layer),
                   size: size,
                   alignToFont: font,
                   contentInsets: contentInsets,
                   verticalAlignment: verticalAlignment,
                   contentMode: contentMode)
    }

    public static func tag(_ string: String,
                           font: UIFont = .systemFont(ofSize: 12),
                           color: UIColor = .label,
                           fillColor: UIColor = .systemYellow,
                           cornerRadius: CGFloat = 3,
                           insets: UIEdgeInsets = UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4)) -> PoText {
        PoText(string)
            .font(font)
            .foregroundColor(color)
            .fill(fillColor, cornerRadius: cornerRadius, insets: insets)
    }

    private func applying(_ update: (NSMutableAttributedString) -> Void) -> Self {
        let newStorage = NSMutableAttributedString(attributedString: storage)
        update(newStorage)
        return Self(storage: newStorage)
    }

    private func updatingHighlight(foregroundColor: UIColor?,
                                   backgroundColor: UIColor?,
                                   update: (inout TextHighlight) -> Void) -> Self {
        applying { text in
            let current = text.po.textHighlight
            var highlight = TextHighlight(attributes: current?.attributes ?? [:])
            highlight.tapAction = current?.tapAction
            highlight.longPressAction = current?.longPressAction
            if let foregroundColor {
                highlight.foregroundColor = foregroundColor
            }
            if let backgroundColor {
                highlight.border = Self.highlightBorder(fillColor: backgroundColor)
            }
            update(&highlight)
            text.po.setTextHighlight(nil, range: text.allRange)
            text.po.setTextHighlight(highlight, range: text.allRange)
        }
    }

    private static func highlightBorder(fillColor: UIColor) -> TextBorder {
        TextBorder(fillColor: fillColor,
                   cornerRadius: 3,
                   insets: UIEdgeInsets(top: -2, left: -1, bottom: -2, right: -1))
    }
}

extension NameSpaceWrapper where Base == String {
    public var text: PoText {
        PoText(base)
    }
}

extension PoLabel {
    public convenience init(_ text: String, frame: CGRect = .zero) {
        self.init(frame: frame)
        self.text = text
    }

    public convenience init(_ attributedText: NSAttributedString, frame: CGRect = .zero) {
        self.init(frame: frame)
        self.attributedText = attributedText
    }

    convenience init(frame: CGRect = .zero,
                     attributeContainer: PoAttributeContainer? = nil,
                     @PoTextBuilder _ builder: () -> NSAttributedString) {
        self.init(frame: frame)
        setText(attributeContainer: attributeContainer, builder)
    }

    func setText(attributeContainer: PoAttributeContainer? = nil,
                 @PoTextBuilder _ builder: () -> NSAttributedString) {
        attributedText = NSAttributedString(attributeContainer: attributeContainer, builder: builder)
    }

    public convenience init(frame: CGRect = .zero,
                            style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                            @PoTextBuilder _ builder: () -> NSAttributedString) {
        self.init(frame: frame)
        setText(style: style, mergePolicy: mergePolicy, builder)
    }

    public func setText(style: PoTextStyle,
                        mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                        @PoTextBuilder _ builder: () -> NSAttributedString) {
        attributedText = NSAttributedString(style: style,
                                            mergePolicy: mergePolicy) {
            builder()
        }
    }

    @discardableResult
    public func lines(_ numberOfLines: Int) -> Self {
        self.numberOfLines = numberOfLines
        return self
    }

    @discardableResult
    public func alignment(_ alignment: NSTextAlignment) -> Self {
        textAlignment = alignment
        return self
    }

    @discardableResult
    public func verticalAlignment(_ alignment: TextVerticalAlignment) -> Self {
        textVerticalAlignment = alignment
        return self
    }

    @discardableResult
    public func insets(_ insets: UIEdgeInsets) -> Self {
        textContainerInsets = insets
        return self
    }

    @discardableResult
    public func lineBreak(_ mode: NSLineBreakMode) -> Self {
        lineBreakMode = mode
        return self
    }

    @discardableResult
    public func asyncDisplay(_ isDisplayedAsynchronously: Bool) -> Self {
        self.isDisplayedAsynchronously = isDisplayedAsynchronously
        return self
    }
}

extension NSMutableAttributedString {
    func po_applyStyle(_ style: PoTextStyle, mergePolicy: PoTextStyleMergePolicy) {
        po_applyAttributes(style.attributes, mergePolicy: mergePolicy)
    }

    func po_applyAttributes(_ attributes: [NSAttributedString.Key: Any], mergePolicy: PoTextStyleMergePolicy) {
        guard length > 0, !attributes.isEmpty else { return }

        switch mergePolicy {
        case .keepLocal:
            var updates: [(range: NSRange, attributes: [NSAttributedString.Key: Any])] = []
            enumerateAttributes(in: allRange, options: []) { currentAttributes, range, _ in
                var missingAttributes: [NSAttributedString.Key: Any] = [:]
                for (key, value) in attributes where currentAttributes[key] == nil {
                    missingAttributes[key] = value
                }
                if !missingAttributes.isEmpty {
                    updates.append((range, missingAttributes))
                }
            }
            for update in updates {
                addAttributes(update.attributes, range: update.range)
            }
        case .overrideLocal:
            addAttributes(attributes, range: allRange)
        }
    }
}
