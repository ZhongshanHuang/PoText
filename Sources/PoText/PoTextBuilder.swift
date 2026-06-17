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
    
    static func buildExpression(_ poAttributedString: PoAttributedString) -> NSAttributedString {
        poAttributedString.content
    }

    public static func buildExpression(_ poText: PoText) -> NSAttributedString {
        poText.attributedString
    }
    
    static func buildExpression(_ poAttachmentString: PoAttachmentString) -> NSAttributedString {
        poAttachmentString.content
    }
    
    public static func buildExpression(_ attributedString: NSAttributedString) -> NSAttributedString {
        attributedString
    }

    public static func buildExpression(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string)
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

    convenience init(attributeContainer: PoAttributeContainer? = nil, @PoTextBuilder builder: () -> NSAttributedString) {
        if attributeContainer != nil {
            let param = NSMutableAttributedString(attributedString: builder())
            param.addAttributes(attributeContainer!.attributes, range: param.allRange)
            self.init(attributedString: param)
        } else {
            self.init(attributedString: builder())
        }
    }

    public convenience init(style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                            @PoTextBuilder builder: () -> NSAttributedString) {
        let param = NSMutableAttributedString(attributedString: builder())
        param.po_applyStyle(style, mergePolicy: mergePolicy)
        self.init(attributedString: param)
    }
    
}

extension NSMutableAttributedString {

    convenience init(attributeContainer: PoAttributeContainer? = nil, @PoTextBuilder mbuilder: () -> NSAttributedString) {
        self.init(attributedString: mbuilder())
        if attributeContainer != nil {
            self.addAttributes(attributeContainer!.attributes, range: allRange)
        }
    }

    public convenience init(style: PoTextStyle,
                            mergePolicy: PoTextStyleMergePolicy = .keepLocal,
                            @PoTextBuilder mbuilder: () -> NSAttributedString) {
        self.init(attributedString: mbuilder())
        po_applyStyle(style, mergePolicy: mergePolicy)
    }
    
}
