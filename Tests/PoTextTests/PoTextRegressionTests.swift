import Testing
import UIKit
@testable import PoText

@Test
func paragraphTransformsKeepReusableTextUnchanged() {
    let base = PoText("base").lineSpacing(3)
    let centered = base.alignment(.center)
    let wrapped = base.lineBreak(.byCharWrapping)

    #expect(base.attributedString.po.alignment == .natural)
    #expect(centered.attributedString.po.alignment == .center)
    #expect(base.attributedString.po.lineBreakMode != .byCharWrapping)
    #expect(wrapped.attributedString.po.lineBreakMode == .byCharWrapping)
    #expect(centered.attributedString.po.lineSpacing == 3)
}

@Test
func paragraphSettersDoNotMutateSharedStylesOrOtherRanges() {
    let updates: [(NSMutableAttributedString) -> Void] = [
        { $0.po.setAlignment(.center, range: NSRange(location: 0, length: 1)) },
        { $0.po.setBaseWritingDirection(.rightToLeft, range: NSRange(location: 0, length: 1)) },
        { $0.po.setLineSpacing(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setParagraphSpacing(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setParagraphSpacingBefore(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setFirstLineHeadIndent(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setHeadIndent(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setTailIndent(-7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setLineBreakMode(.byCharWrapping, range: NSRange(location: 0, length: 1)) },
        { $0.po.setMinimumLineHeight(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setMaximumLineHeight(70, range: NSRange(location: 0, length: 1)) },
        { $0.po.setLineHeightMultiple(2, range: NSRange(location: 0, length: 1)) },
        { $0.po.setHyphenationFactor(0.5, range: NSRange(location: 0, length: 1)) },
        { $0.po.setDefaultTabInterval(7, range: NSRange(location: 0, length: 1)) },
        { $0.po.setTabStops([], range: NSRange(location: 0, length: 1)) }
    ]

    for update in updates {
        let sharedStyle = NSMutableParagraphStyle()
        sharedStyle.lineSpacing = 2
        sharedStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        let expectedStyle = sharedStyle.copy() as! NSParagraphStyle
        let original = NSAttributedString(string: "ab", attributes: [.paragraphStyle: sharedStyle])
        let modified = NSMutableAttributedString(attributedString: original)

        update(modified)

        #expect(sharedStyle == expectedStyle)
        #expect(original.po.paragraphStyle == expectedStyle)
        #expect(modified.po.paragraphStyle(at: 1) == expectedStyle)
        #expect(modified.po.paragraphStyle(at: 0) != expectedStyle)
    }
}

@Test
func layoutKeepsSourceParagraphStyleUnchanged() {
    let source = PoText("text").lineSpacing(3).lineBreak(.byTruncatingTail)
    let layout = TextLayout(attributedString: source.attributedString,
                            container: TextContainer(size: CGSize(width: 100, height: 40)))

    #expect(source.attributedString.po.lineBreakMode == .byTruncatingTail)
    #expect(layout.attributedString.po.lineBreakMode == .byWordWrapping)
}

@Test
func appendingPlainTextClearsActionsAndKeepsVisualStyle() {
    let original = PoText.link("link") { _ in }.font(.systemFont(ofSize: 15))
    let appended = original.appending(" plain 👋").attributedString

    #expect(original.attributedString.po.textHighlight != nil)
    #expect(appended.po.textHighlight(at: 0) != nil)
    #expect(appended.po.textHighlight(at: 5) == nil)
    #expect(appended.po.foregroundColor(at: 5) == .systemBlue)
    #expect(appended.po.font(at: 5) == .systemFont(ofSize: 15))

    let nativeLink = PoText("link", attributes: [.link: URL(string: "https://example.com")!])
        .appending(" plain").attributedString
    #expect(nativeLink.po.attribute(.link, at: 5) == nil)
    #expect(nativeLink.po.attribute(.link, at: 0) != nil)
}

@MainActor
@Test
func settingPlainTextClearsPreviousActionsEvenWhenTheStringIsUnchanged() {
    for replacement in ["link", "new plain text"] {
        let label = PoLabel(attributedText: PoText.link("link") { _ in }.attributedString)
        label.text = replacement

        #expect(label.text == replacement)
        #expect(label.attributedText?.po.textHighlight == nil)
    }
}

@MainActor
@Test
func repeatedImageAttachmentsHaveSeparateDrawingPositions() {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in
        UIColor.systemRed.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    let icon = PoText.attachment(image, size: CGSize(width: 10, height: 10))
    let text = NSAttributedString { icon; icon; icon }
    let layout = TextLayout(attributedString: text,
                            container: TextContainer(size: CGSize(width: 100, height: 40)))

    #expect(layout.imageAttachmentInfos.count == 3)
    #expect(Set(layout.imageAttachmentInfos.map { $0.proposedRect.minX }).count == 3)
    #expect(layout.imageAttachmentInfos.allSatisfy { $0.proposedRect.width == 10 })

    let wrapped = TextLayout(attributedString: text,
                             container: TextContainer(size: CGSize(width: 10, height: 100)))
    #expect(wrapped.imageAttachmentInfos.count == 3)
    #expect(Set(wrapped.imageAttachmentInfos.map { $0.proposedRect.minY }).count == 3)
}

@MainActor
@Test
func attributeContainerBuildersUseTheSameBasePrecedenceAsStyles() {
    let attributes = PoAttributeContainer().foregroundColor(UIColor.red).kern(2)
    let style = PoTextStyle(attributes)
    let local = PoText("local").foregroundColor(.blue)
    let immutable = NSAttributedString(attributeContainer: attributes) { local }
    let mutable = NSMutableAttributedString(attributeContainer: attributes) { local }
    let styled = NSAttributedString(style: style) { local }
    let label = PoLabel(attributeContainer: attributes) { local }

    for text in [immutable, mutable, styled, label.attributedText!] {
        #expect(text.po.foregroundColor == .blue)
        #expect(text.po.kern == 2)
    }
}

@MainActor
@Test
func attributeContainerBuildersCanExplicitlyOverrideLocalAttributes() {
    let attributes = PoAttributeContainer().foregroundColor(UIColor.red)
    let local = PoText("local").foregroundColor(.blue)
    let immutable = NSAttributedString(attributeContainer: attributes, mergePolicy: .overrideLocal) { local }
    let mutable = NSMutableAttributedString(attributeContainer: attributes, mergePolicy: .overrideLocal) { local }
    let label = PoLabel(attributeContainer: attributes, mergePolicy: .overrideLocal) { local }

    for text in [immutable, mutable, label.attributedText!] {
        #expect(text.po.foregroundColor == .red)
    }
    label.setText(attributeContainer: attributes) { local }
    #expect(label.attributedText?.po.foregroundColor == .blue)
    label.setText(attributeContainer: attributes, mergePolicy: .overrideLocal) { local }
    #expect(label.attributedText?.po.foregroundColor == .red)
}

@Test
func plainStringInsertionAndAppendClearDiscontinuousAttributes() {
    let original = NSMutableAttributedString(attributedString: PoText.link("link") { _ in }.attributedString)
    original.po.setTextBackedString(TextBackedString(rawValue: "source"), range: original.allRange)
    original.po.setLink(URL(string: "https://example.com")!, range: original.allRange)
    original.po.insert("👋", at: 2)
    original.po.append(" plain")

    for index in [2, 3, 6] {
        for key in NSAttributedString.Key.allDiscontinuousAttributeKeys {
            #expect(original.po.attribute(key, at: index) == nil)
        }
    }
    #expect(original.po.textHighlight(at: 0) != nil)
    #expect(original.po.textHighlight(at: 4) != nil)
}

@Test
func paragraphStyleSetterTakesASnapshotOfMutableInput() {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 3
    let text = PoText("text").paragraphStyle(style)

    style.lineSpacing = 20

    #expect(text.attributedString.po.lineSpacing == 3)
}

@Test
func appendingPlainTextDoesNotInheritAnAttachment() {
    let attachment = NSTextAttachment()
    let original = PoText(NSAttributedString(attachment: attachment))
    let appended = original.appending("plain").attributedString

    #expect(appended.string == "\u{FFFC}plain")
    #expect(appended.po.attribute(.attachment, at: 0) as? NSTextAttachment === attachment)
    #expect(appended.po.attribute(.attachment, at: 1) == nil)
}
