import Testing
import UIKit
@testable import PoText

@MainActor
@Test func nativeControlAttachmentReservesItsFittedSize() throws {
    let switcher = UISwitch()
    switcher.sizeToFit()
    let fittedSize = switcher.bounds.size
    let text = PoText.attachment(switcher).attributedString
    let attachment = try #require(text.attribute(.attachment, at: 0, effectiveRange: nil) as? TextAttachment)

    #expect(attachment.bounds.size == fittedSize)
    let layout = TextLayout(attributedString: text, container: TextContainer(size: CGSize(width: 300, height: 100)))
    let host = UIView()
    layout.drawAttachments(in: host, at: .zero, size: CGSize(width: 300, height: 100))
    #expect(abs(switcher.frame.width - fittedSize.width) < 0.5)
    #expect(abs(switcher.frame.height - fittedSize.height) < 0.5)
}

@MainActor
@Test func resizingCustomTruncationKeepsNativeControlAndTokenSeparate() throws {
    let font = UIFont.systemFont(ofSize: 16)
    let switcher = UISwitch()
    switcher.sizeToFit()
    let image = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 28)).image { _ in }
    let text = NSAttributedString(style: PoTextStyle(font: font)) {
        "This is UIImage attachment:"
        PoText.attachment(image, alignToFont: font, verticalAlignment: .top)
        "\nThis is UIView attachment:"
        PoText.attachment(switcher, alignToFont: font, verticalAlignment: .center)
        "\nThis is Animated Image attachment: more content that should truncate"
    }
    let more = PoLabel(PoText("…more").font(font).attributedString)
    more.sizeToFit()
    let label = PoLabel(text).asyncDisplay(false).lines(0).verticalAlignment(.top)
    label.tailTruncationToken = PoText.attachment(more, alignToFont: font, verticalAlignment: .center).attributedString
    var sawControlAndToken = false
    var sawTruncatedControl = false

    for width in [CGFloat(280), 300, 320, 340] {
        // Shrinking and growing the same label also checks stale hosted views.
        for height in [CGFloat(260), 90, 80, 72, 65, 55, 260] {
            label.bounds.size = CGSize(width: width, height: height)
            label.layer.display()
            let layout = try #require(label.textLayout)
            let expectedViews = Set(layout.hostedAttachmentInfos.compactMap { info -> ObjectIdentifier? in
                if case .view(let view) = info.attachment.content { return ObjectIdentifier(view) }
                return nil
            })
            #expect(Set(label._attachmentViews.map(ObjectIdentifier.init)) == expectedViews)
            for view in [switcher, more] as [UIView] {
                #expect((view.superview === label) == expectedViews.contains(ObjectIdentifier(view)))
            }
            if switcher.superview === label && more.superview === label {
                sawControlAndToken = true
                let overlap = switcher.frame.intersection(more.frame)
                #expect(overlap.isNull || overlap.width < 0.5 || overlap.height < 0.5)
            }
            if switcher.superview !== label && more.superview === label { sawTruncatedControl = true }

            // Native controls must not extend backwards over the preceding text.
            layout.textStorage.enumerateAttribute(.attachment, in: layout.visibleCharacterRange) { value, range, _ in
                guard let attachment = value as? TextAttachment,
                      case .view(let view) = attachment.content, range.location > 0 else { return }
                let glyph = layout.layoutManager.glyphIndexForCharacter(at: range.location - 1)
                let previousRect = layout.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: layout.textContainer)
                if previousRect.midY >= view.frame.minY && previousRect.midY <= view.frame.maxY {
                    #expect(previousRect.maxX <= view.frame.minX + 0.5)
                }
            }
        }
    }
    #expect(sawControlAndToken)
    #expect(sawTruncatedControl)
}
