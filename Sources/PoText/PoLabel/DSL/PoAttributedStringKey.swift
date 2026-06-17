import UIKit

// MARK: - PoAttributedStringKey

protocol PoAttributedStringKey {
    associatedtype Value : Hashable
    static var name : NSAttributedString.Key { get }
}

extension PoAttributedStringKey {
    var description: String { Self.name.rawValue }
}

// MARK: - PoAttributeDynamicLookup

@dynamicMemberLookup
enum PoAttributeDynamicLookup: Sendable {
    
    subscript<T: PoAttributedStringKey>(_: T.Type) -> T {
        get { fatalError("Called outside of a dynamicMemberLookup subscript overload") }
    }
    
    subscript<T: PoAttributedStringKey>(dynamicMember keyPath: KeyPath<PoTextAttributesScopes, T>) -> T {
        self[T.self]
    }
}

// MARK: - PoTextAttributesScopes

struct PoTextAttributesScopes: Sendable {
    /// 字体
    let font: PoTextAttributesScopes.FontAttribute = FontAttribute()
    /// 文字间隔(负数缩紧，正数散开)
    let kern: PoTextAttributesScopes.KernAttribute = KernAttribute()
    /// 文字颜色
    let foregroundColor: PoTextAttributesScopes.ForegroundColorAttribute = ForegroundColorAttribute()
    /// 背景颜色 /* PoLabel不支持, 请使用textBorder替代 */
    let backgroundColor: PoTextAttributesScopes.BackgroundColorAttribute = BackgroundColorAttribute()
    /// 文字的外面的线宽 (正数会变成空心字，负数会加宽文字的线条)
    let strokeWidth: PoTextAttributesScopes.StrokeWidthAttribute = StrokeWidthAttribute()
    /// 文字颜色，与strokeWidth一同设置才生效
    let strokeColor: PoTextAttributesScopes.StrokeColorAttribute = StrokeColorAttribute()
    /// 文字阴影
    let shadow: PoTextAttributesScopes.ShadowAttribute = ShadowAttribute()
    /// 文字删除线  /* PoLabel不支持, 请使用textStrikethroughStyle */
    let strikethroughStyle: PoTextAttributesScopes.StrikethroughStyleAttribute = StrikethroughStyleAttribute()
    /// 文字删除线颜色 /* PoLabel不支持, 请使用textStrikethroughColor */
    let strikethroughColor: PoTextAttributesScopes.StrikethroughColorAttribute = StrikethroughColorAttribute()
    /// 下划线
    let underlineStyle: PoTextAttributesScopes.UnderlineStyleAttribute = UnderlineStyleAttribute()
    /// 下划线颜色
    let underlineStyleColor: PoTextAttributesScopes.UnderlineColorAttribute = UnderlineColorAttribute()
    /// 连体字符，0:不生效，1:使用默认的连体字符。(只有某些字体才支持)
    let ligature: PoTextAttributesScopes.LigatureAttribute = LigatureAttribute()
    /// 凸版印刷效果, NSAttributedString.TextEffectStyle.letterpressStyle /* PoLabel不支持 */
    let textEffect: PoTextAttributesScopes.TextEffectAttribute = TextEffectAttribute()
    /// 基线偏移量(正数:向上偏移，负数:向下偏移)
    let baselineOffset: PoTextAttributesScopes.BaselineOffsetAttribute = BaselineOffsetAttribute()
    /// 文字布局方向
    let writingDirection: PoTextAttributesScopes.WritingDirectionAttribute = WritingDirectionAttribute()
    /// 文字倾斜(正数：右倾斜，负数：左倾斜) /* PoLabel不支持 */
    let obliqueness: PoTextAttributesScopes.ObliquenessAttribute = ObliquenessAttribute()
    /// 字体的横向拉伸(正数：拉伸，负数：压缩) /* PoLabel不支持 */
    let expansion: PoTextAttributesScopes.ExpansionAttribute = ExpansionAttribute()
    /// 设置文字排版方向，0表示横排文本，1表示竖排文本 在iOS中只支持0 /* PoLabel不支持 */
    let verticalGlyphForm: PoTextAttributesScopes.VerticalGlyphFormAttribute = VerticalGlyphFormAttribute()
    /// 段落样式
    let paragraphStyle: PoTextAttributesScopes.ParagraphStyleAttribute = ParagraphStyleAttribute()
    
    /* 自定义属性 */
    
    /// 文字边框
    let textBorder: PoTextAttributesScopes.TextBorderAttribute = TextBorderAttribute()
    /// 文字块边框
    let textBlockBorder: PoTextAttributesScopes.TextBlockBorderAttribute = TextBlockBorderAttribute()
    /// 高亮
    let textHighlight: PoTextAttributesScopes.TextHighlightAttribute = TextHighlightAttribute()
        
    struct FontAttribute: PoAttributedStringKey, Sendable {
        typealias Value = UIFont
        static let name: NSAttributedString.Key = NSAttributedString.Key.font
    }
    
    struct KernAttribute: PoAttributedStringKey, Sendable {
        typealias Value = CGFloat
        static let name: NSAttributedString.Key = NSAttributedString.Key.kern
    }
    
    struct ForegroundColorAttribute: PoAttributedStringKey, Sendable {
        typealias Value = UIColor
        static let name: NSAttributedString.Key = NSAttributedString.Key.foregroundColor
    }
    
    struct BackgroundColorAttribute: PoAttributedStringKey, Sendable {
        typealias Value = UIColor
        static let name: NSAttributedString.Key = NSAttributedString.Key.backgroundColor
    }
    
    struct StrokeWidthAttribute: PoAttributedStringKey, Sendable {
        typealias Value = CGFloat
        static let name: NSAttributedString.Key = NSAttributedString.Key.strokeWidth
    }
    
    struct StrokeColorAttribute: PoAttributedStringKey, Sendable {
        typealias Value = UIColor
        static let name: NSAttributedString.Key = NSAttributedString.Key.strokeColor
    }
    
    struct ShadowAttribute: PoAttributedStringKey, Sendable {
        typealias Value = NSShadow
        static let name: NSAttributedString.Key = NSAttributedString.Key.shadow
    }
    
    struct StrikethroughStyleAttribute: PoAttributedStringKey, Sendable {
        typealias Value = NSUnderlineStyle
        static let name: NSAttributedString.Key = NSAttributedString.Key.strikethroughStyle
    }
    
    struct StrikethroughColorAttribute: PoAttributedStringKey, Sendable {
        typealias Value = UIColor
        static let name: NSAttributedString.Key = NSAttributedString.Key.strikethroughColor
    }
    
    struct UnderlineStyleAttribute: PoAttributedStringKey, Sendable {
        typealias Value = NSUnderlineStyle
        static let name: NSAttributedString.Key = NSAttributedString.Key.underlineStyle
    }
    
    struct UnderlineColorAttribute: PoAttributedStringKey, Sendable {
        typealias Value = UIColor
        static let name: NSAttributedString.Key = NSAttributedString.Key.underlineColor
    }
    
    struct LigatureAttribute: PoAttributedStringKey, Sendable {
        typealias Value = Int
        static let name: NSAttributedString.Key = NSAttributedString.Key.ligature
    }
    
    struct TextEffectAttribute: PoAttributedStringKey, Sendable {
        typealias Value = NSAttributedString.TextEffectStyle
        static let name: NSAttributedString.Key = NSAttributedString.Key.textEffect
    }
    
    struct BaselineOffsetAttribute: PoAttributedStringKey, Sendable {
        typealias Value = CGFloat
        static let name: NSAttributedString.Key = NSAttributedString.Key.baselineOffset
    }
    
    struct WritingDirectionAttribute: PoAttributedStringKey, Sendable {
        typealias Value = [Int]
        static let name: NSAttributedString.Key = NSAttributedString.Key.writingDirection
    }
        
    struct ObliquenessAttribute: PoAttributedStringKey, Sendable {
        typealias Value = CGFloat
        static let name: NSAttributedString.Key = NSAttributedString.Key.obliqueness
    }
    
    struct ExpansionAttribute: PoAttributedStringKey, Sendable {
        typealias Value = CGFloat
        static let name: NSAttributedString.Key = NSAttributedString.Key.expansion
    }
    
    struct VerticalGlyphFormAttribute: PoAttributedStringKey, Sendable {
        typealias Value = Int
        static let name: NSAttributedString.Key = NSAttributedString.Key.verticalGlyphForm
    }
    
    struct ParagraphStyleAttribute: PoAttributedStringKey, Sendable {
        typealias Value = NSParagraphStyle
        static let name: NSAttributedString.Key = NSAttributedString.Key.paragraphStyle
    }
    
    struct TextBorderAttribute: PoAttributedStringKey, Sendable {
        typealias Value = TextBorder
        static let name: NSAttributedString.Key = NSAttributedString.Key.poBorder
    }
    
    struct TextBlockBorderAttribute: PoAttributedStringKey, Sendable {
        typealias Value = TextBorder
        static let name: NSAttributedString.Key = NSAttributedString.Key.poBlockBorder
    }
    
    struct TextHighlightAttribute: PoAttributedStringKey, Sendable {
        typealias Value = TextHighlight
        static let name: NSAttributedString.Key = NSAttributedString.Key.poHighlight
    }
    
}

extension NSUnderlineStyle: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension CGAffineTransform:  @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(a)
        hasher.combine(b)
        hasher.combine(c)
        hasher.combine(d)
        hasher.combine(tx)
        hasher.combine(ty)
    }
}
