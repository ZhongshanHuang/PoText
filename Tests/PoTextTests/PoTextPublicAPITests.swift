import Testing
import UIKit
@testable import PoText

private struct TestAttributeKey: PoAttributedStringKey {
    typealias Value = String
    static let name = NSAttributedString.Key("PoTextTests.testAttribute")
}

@Test
func publicAttributeContainerSupportsTypedAndCustomKeys() {
    let font = UIFont.systemFont(ofSize: 15)
    let container = PoAttributeContainer()
        .font(font)
        .underlineStyle(.single)

    let custom = container[TestAttributeKey.self]
    #expect(container.font == font)
    #expect(container.underlineStyle == .single)
    #expect(custom == nil)

    var withCustom = container
    withCustom[TestAttributeKey.self] = "value"
    #expect(withCustom[TestAttributeKey.self] == "value")
    #expect(withCustom.removingAttribute(TestAttributeKey.name)[TestAttributeKey.self] == nil)
}

@Test
func publicTextContainerClampsInvalidLineCount() {
    var container = TextContainer()
    container.maximumNumberOfLines = -1
    #expect(container.maximumNumberOfLines == 0)
}

@Test
func publicAttributedStringFragmentIsValueSemantic() {
    let base = "Hello".asAttributedString()
    let styled = base.font(.boldSystemFont(ofSize: 18)).foregroundColor(.systemRed)

    #expect(base.font == nil)
    #expect(styled.font == .boldSystemFont(ofSize: 18))
    #expect(styled.foregroundColor == .systemRed)
    #expect(styled.string == "Hello")
    #expect(styled.length == 5)
}

@Test
func builderAcceptsOptionalAndSubstringValues() {
    let value: String? = "optional"
    let source = "substring"
    let text = NSAttributedString {
        value
        source.dropLast(3)
        Optional<PoText>.none
    }

    #expect(text.string == "optionalsubstr")
}

@MainActor
@Test
func poTextAndLabelProvideFoundationAndUIKitStyleConvenienceAPIs() {
    let style = PoTextStyle.body.alignment(.center).lineSpacing(2)
    let styledText = PoText(string: "styled", style: style)
    let text = PoText(string: "styled", attributes: [.foregroundColor: UIColor.systemBlue])
        .addingAttributes([.kern: CGFloat(1)])
        .removingAttribute(.kern)
        .appending(" text")

    #expect(styledText.string == "styled")
    #expect(styledText.attributedString.po.font == style.attributeContainer.font)
    #expect(styledText.attributedString.po.alignment == .center)
    #expect(styledText.attributedString.po.lineSpacing == 2)
    #expect(text.string == "styled text")
    #expect(text.length == "styled text".utf16.count)
    #expect(text.description == text.string)

    let backed = NSMutableAttributedString(string: "backed")
    backed.po.setTextBackedString(TextBackedString(rawValue: "source"), range: backed.allRange)
    let appended = PoText("prefix").appending(backed).attributedString
    #expect(appended.po.plainText(for: NSRange(location: 6, length: 6)) == "source")

    let attributed = NSAttributedString(string: "hello", style: style)
    let label = PoLabel(text: attributed.string)
        .numberOfLines(2)
        .textAlignment(.center)
        .textVerticalAlignment(.top)
        .textContainerInsets(.init(top: 1, left: 2, bottom: 3, right: 4))
        .lineBreakMode(.byWordWrapping)
        .displaysAsynchronously(false)

    #expect(attributed.string == "hello")
    #expect(label.text == "hello")
    #expect(label.numberOfLines == 2)
    #expect(label.textAlignment == .center)
    #expect(label.textVerticalAlignment == .top)
    #expect(label.textInsets == .init(top: 1, left: 2, bottom: 3, right: 4))
    #expect(!label.displaysAsynchronously)
}

@MainActor
@Test
func namedAttachmentInitializersAndNamedLabelInitializersAreAvailable() {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in
        UIColor.systemBlue.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 4, height: 4)).fill()
    }
    let attachment = TextAttachment(image: image, size: CGSize(width: 8, height: 8))
    let imageText = NSAttributedString(attachment: attachment)
    let label = PoLabel(attributedText: imageText)

    #expect(attachment.content == .image(image))
    #expect(label.attributedText?.length == 1)
}

@MainActor
@Test
func labelMeasurementQueriesReuseCacheAndKeepRenderLayout() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
    label.isDisplayedAsynchronously = false
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.text = "A repeated measurement should not replace the render layout."

    let renderLayout = label.textLayout
    let renderContainerSize = label._innerContainer.size

    let firstSize = label.sizeThatFits(CGSize(width: 100, height: 200))
    let measurementLayout = label._measurementLayout
    let secondSize = label.sizeThatFits(CGSize(width: 100, height: 200))
    let intrinsicSize = label.intrinsicContentSize

    #expect(measurementLayout != nil)
    #expect(label._measurementLayout === measurementLayout)
    #expect(firstSize == secondSize)
    #expect(intrinsicSize == firstSize)
    #expect(label._innerContainer.size == renderContainerSize)
    #expect(label.textLayout === renderLayout)
}

@MainActor
@Test
func sizeToFitPromotesTheFreshMeasurementLayout() {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 180, height: 20)).image { _ in
        UIColor.systemBlue.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: 180, height: 20)).fill()
    }
    let attachment = TextAttachment(image: image, size: CGSize(width: 180, height: 20))
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 180, height: 0))
    label.isDisplayedAsynchronously = false
    label.numberOfLines = 1
    label.lineBreakMode = .byWordWrapping
    label.attributedText = NSAttributedString(attachment: attachment)

    let previousRenderLayout = label.textLayout
    let fittedSize = label.sizeThatFits(label.bounds.size)
    let measuredLayout = label._measurementLayout
    label.frame = CGRect(origin: label.frame.origin, size: fittedSize)

    #expect(previousRenderLayout != nil)
    #expect(measuredLayout != nil)
    #expect(label.textLayout === measuredLayout)
    #expect(label.textLayout !== previousRenderLayout)
    #expect(!label._state.isLayoutNeedUpdate)
    label.layer.display()
    #expect(label.textLayout === measuredLayout)
}

@MainActor
@Test
func sizeToFitDoesNotReuseAWiderCenteredMeasurement() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 180, height: 0))
    label.isDisplayedAsynchronously = false
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.textAlignment = .center
    label.text = "A centered string must be laid out again at its final fitting width."

    let fittedSize = label.sizeThatFits(label.bounds.size)
    let measuredLayout = label._measurementLayout
    label.frame = CGRect(origin: label.frame.origin, size: fittedSize)
    let renderLayout = label.textLayout

    #expect(measuredLayout != nil)
    #expect(renderLayout !== measuredLayout)
    #expect(renderLayout?.container.size.width == fittedSize.width)
}

@MainActor
@Test
func repeatedSynchronousRenderPreparationReusesLayout() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 180, height: 40))
    label.isDisplayedAsynchronously = false
    label.text = "A synchronous display should prepare its layout only once."

    let firstContext = label.asyncLayerPrepareForRenderContext()
    let secondContext = label.asyncLayerPrepareForRenderContext()

    #expect(firstContext.layout != nil)
    #expect(secondContext.layout === firstContext.layout)
}

@MainActor
@Test
func preferredMaxLayoutWidthInvalidatesOnlyMeasurementForNewWidth() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 220, height: 80))
    label.isDisplayedAsynchronously = false
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.text = "A long string needs more than one line when its preferred width is narrow."

    let wideSize = label.sizeThatFits(CGSize(width: 220, height: 200))
    let wideMeasurement = label._measurementLayout
    let renderLayout = label.textLayout
    label.preferredMaxLayoutWidth = 80
    let narrowSize = label.sizeThatFits(CGSize(width: 220, height: 200))

    #expect(wideMeasurement != nil)
    #expect(label._measurementLayout !== wideMeasurement)
    #expect(narrowSize.height > wideSize.height)
    #expect(label.textLayout === renderLayout)
}

@MainActor
@Test
func verticalAlignmentChangesRedrawWithoutRebuildingLayout() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 160, height: 50))
    label.isDisplayedAsynchronously = false
    label.text = "Keep the glyph layout while changing its drawing origin."

    let layout = label.textLayout
    label.textVerticalAlignment = .top

    #expect(label.textLayout === layout)
    #expect(!label._state.isLayoutNeedUpdate)
}

@MainActor
@Test
func attributedTextGetterReturnsAnIndependentSnapshot() {
    let label = PoLabel(text: "snapshot")
    guard let attributedText = label.attributedText else {
        Issue.record("Expected attributed text")
        return
    }
    let value = NSMutableAttributedString(attributedString: attributedText)

    value.mutableString.setString("mutated")

    #expect(label.text == "snapshot")
}

@MainActor
@Test
func labelConfigureAppliesACompleteConfiguration() {
    let label = PoLabel()
        .configure { label in
            label.text = "batched"
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textContainerInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
            label.displaysAsynchronously = false
        }

    #expect(label.text == "batched")
    #expect(label.numberOfLines == 0)
    #expect(label.textAlignment == .center)
    #expect(label.textInsets == UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4))
    #expect(!label.displaysAsynchronously)
}

@MainActor
@Test
func ignoredCommonPropertiesKeepTheExplicitLayout() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 160, height: 40))
    label.isDisplayedAsynchronously = false
    label.text = "layout source"
    let layout = label.textLayout

    label.isIgnoredCommonProperties = true
    label.font = .boldSystemFont(ofSize: 22)
    label.textColor = .systemRed

    #expect(label.textLayout === layout)

    label.isIgnoredCommonProperties = false
    let refreshedLayout = label.textLayout
    #expect(refreshedLayout != nil)
    #expect(refreshedLayout !== layout)
}

@MainActor
@Test
func ignoredCommonPropertiesDoNotBuildACommonLayout() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 160, height: 40))
    label.isDisplayedAsynchronously = false
    label.text = "common text"
    label.isIgnoredCommonProperties = true

    #expect(label.textLayout == nil)
    let context = label.asyncLayerPrepareForRenderContext()
    #expect(context.layout == nil)
    #expect(context.text.length == 0)
    #expect(!context.hasRenderableContent)
}
