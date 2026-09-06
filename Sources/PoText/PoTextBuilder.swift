import Foundation

@resultBuilder
public enum PoTextBuilder {
    public static func buildBlock() -> NSAttributedString {
        NSAttributedString()
    }

    public static func buildBlock(_ components: NSAttributedString...) -> NSAttributedString {
        let result = components.reduce(into: NSMutableAttributedString()) { result, next in
            result.append(next)
        }
        return result
    }
    
    public static func buildExpression(_ poAttributedString: PoAttributedString) -> NSAttributedString {
        poAttributedString.content
    }

    public static func buildExpression(_ poAttributedString: PoAttributedString?) -> NSAttributedString {
        poAttributedString?.content ?? NSAttributedString()
    }

    public static func buildExpression(_ poText: PoText) -> NSAttributedString {
        poText.attributedString
    }

    public static func buildExpression(_ poText: PoText?) -> NSAttributedString {
        poText?.attributedString ?? NSAttributedString()
    }
    
    public static func buildExpression(_ poAttachmentString: PoAttachmentString) -> NSAttributedString {
        poAttachmentString.content
    }

    public static func buildExpression(_ poAttachmentString: PoAttachmentString?) -> NSAttributedString {
        poAttachmentString?.content ?? NSAttributedString()
    }
    
    public static func buildExpression(_ attributedString: NSAttributedString) -> NSAttributedString {
        attributedString
    }

    public static func buildExpression(_ attributedString: NSAttributedString?) -> NSAttributedString {
        attributedString ?? NSAttributedString()
    }

    public static func buildExpression(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string)
    }

    public static func buildExpression(_ substring: Substring) -> NSAttributedString {
        NSAttributedString(string: String(substring))
    }

    public static func buildExpression(_ attributedString: AttributedString) -> NSAttributedString {
        NSAttributedString(attributedString)
    }

    public static func buildExpression(_ string: String?) -> NSAttributedString {
        NSAttributedString(string: string ?? "")
    }
    
    public static func buildOptional(_ component: NSAttributedString?) -> NSAttributedString {
        component ?? NSAttributedString()
    }

    public static func buildEither(first component: NSAttributedString) -> NSAttributedString {
        component
    }
    
    public static func buildEither(second component: NSAttributedString) -> NSAttributedString {
        component
    }

    public static func buildArray(_ components: [NSAttributedString]) -> NSAttributedString {
        let result = components.reduce(into: NSMutableAttributedString()) { result, next in
            result.append(next)
        }
        return result
    }

    public static func buildLimitedAvailability(_ component: NSAttributedString) -> NSAttributedString {
        component
    }
}

extension NSAttributedString {

    /// Bridges to Swift's native ``AttributedString``.
    public var swiftAttributedString: AttributedString {
        AttributedString(self)
    }

    public convenience init(attributeContainer: PoAttributeContainer? = nil,
                            @PoTextBuilder builder: () -> NSAttributedString) {
        let result = NSMutableAttributedString(attributedString: builder())
        if let attributeContainer, result.length > 0 {
            result.addAttributes(attributeContainer.attributes, range: result.allRange)
        }
        self.init(attributedString: result)
    }

    public convenience init(style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                            @PoTextBuilder builder: () -> NSAttributedString) {
        let param = NSMutableAttributedString(attributedString: builder())
        param.po_applyStyle(style, mergePolicy: mergePolicy)
        self.init(attributedString: param)
    }

    /// Creates an attributed string by applying a style to a plain string.
    public convenience init(string: String,
                            style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal) {
        self.init(style: style, mergePolicy: mergePolicy) { string }
    }
    
}

extension NSMutableAttributedString {

    public convenience init(attributeContainer: PoAttributeContainer? = nil,
                            @PoTextBuilder mbuilder: () -> NSAttributedString) {
        self.init(attributedString: mbuilder())
        if let attributeContainer, length > 0 {
            self.addAttributes(attributeContainer.attributes, range: allRange)
        }
    }

    public convenience init(style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                            @PoTextBuilder mbuilder: () -> NSAttributedString) {
        self.init(attributedString: mbuilder())
        po_applyStyle(style, mergePolicy: mergePolicy)
    }

    /// Creates a mutable attributed string by applying a style to a plain
    /// string.
    public convenience init(styledString string: String,
                            style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal) {
        self.init(string: string)
        po_applyStyle(style, mergePolicy: mergePolicy)
    }
    
}
