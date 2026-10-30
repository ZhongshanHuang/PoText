import Testing
import UIKit
@testable import PoText

private let renderSize = CGSize(width: 100, height: 40)

@MainActor
@Test func renderRequestSnapshotsMutableInputs() {
    let text = NSMutableAttributedString(string: "before")
    let token = NSMutableAttributedString(string: "more")
    let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 4, height: 4))
    var container = TextContainer(size: renderSize)
    container.tailTruncationToken = token
    container.exclusionPaths = [path]
    let request = makeRequest(text: text, container: container)
    text.mutableString.setString("after")
    token.mutableString.setString("changed")
    path.removeAllPoints()
    guard case .text(let snapshot) = request.source else { Issue.record("Expected snapshot"); return }
    #expect(snapshot.text.string == "before")
    #expect(snapshot.container.tailTruncationToken?.string == "more")
    #expect(snapshot.container.exclusionPaths?.first?.isEmpty == false)
}

@MainActor
@Test func synchronousLayerDisplayCommitsContentsAndLayout() {
    let (layer, delegate) = makeLayer(asynchronously: false)
    layer.display()
    #expect(layer.contents != nil)
    #expect(delegate.completedTexts == ["first"])
    #expect(delegate.lastResult?.layout != nil)
}

@MainActor
@Test func asynchronousLayerDisplayCommitsBackOnMainActor() async throws {
    let (layer, delegate) = makeLayer()
    layer.display()
    try await waitForDisplay(delegate)
    #expect(layer.contents != nil)
    #expect(delegate.completedTexts == ["first"])
}

@MainActor
@Test func supersededDisplaysCannotCommitAnOlderResult() async throws {
    let (layer, delegate) = makeLayer()
    for index in 0..<100 {
        delegate.text = "value \(index)"
        layer.setNeedsDisplay()
        layer.display()
    }
    try await waitForDisplay(delegate)
    #expect(delegate.completedTexts == ["value 99"])
}

@MainActor
@Test func emptyDisplayClearsWithoutBackgroundWork() {
    let (layer, delegate) = makeLayer(asynchronously: false)
    layer.display()
    #expect(layer.contents != nil)
    delegate.text = ""
    layer.isDisplayedAsynchronously = true
    layer.display()
    #expect(layer.contents == nil)
    #expect(delegate.lastResult?.layout == nil)
    #expect(delegate.completedTexts == ["first", ""])
}

@MainActor
@Test(arguments: [false, true])
func labelDisplaysUsingTheRenderSnapshot(asynchronously: Bool) async throws {
    let label = PoLabel(frame: CGRect(origin: .zero, size: renderSize))
    label.isDisplayedAsynchronously = asynchronously
    label.text = "PoText"
    label.layer.display()
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(3))
    while label.layer.contents == nil && clock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
    #expect(label.layer.contents != nil)
    #expect(label.textLayout?.textStorage.string == "PoText")
}

@MainActor
@Test func redrawReusesLayoutWithoutSnapshottingText() throws {
    let label = PoLabel(frame: CGRect(origin: .zero, size: renderSize))
    label.isDisplayedAsynchronously = false
    label.text = "cached"
    label.layer.display()
    let original = label.textLayout
    label.textVerticalAlignment = .top
    let request = label.asyncLayerPrepare(label.layer)
    guard case .layout(let cached) = request.source else { Issue.record("Expected cached layout"); return }
    #expect(cached === original)
    #expect(!request.shouldCommitLayout)
    let result = try PoTextRenderer.renderImmediately(request)
    #expect(result.layout === cached)
    #expect(result.drawingPoint.y == 0)
    label.layer.display()
    #expect(label.textLayout === original)
}

@MainActor
@Test func measurementDoesNotReplaceRenderLayoutAndInvalidatesWithContent() {
    let label = PoLabel(frame: CGRect(origin: .zero, size: renderSize))
    label.text = "a long paragraph that wraps at a narrow width"
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    let original = label.textLayout
    let narrow = label.sizeThatFits(CGSize(width: 30, height: 1_000))
    #expect(narrow == label.sizeThatFits(CGSize(width: 30, height: 1_000)))
    #expect(label.textLayout === original)
    #expect(label.textLayout?.container.size == renderSize)
    label.text = "short"
    #expect(label.sizeThatFits(CGSize(width: 30, height: 1_000)).height < narrow.height)
}

@MainActor
@Test func lineCountChangesKeepPropertiesAndMeasurementInSync() {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    label.lineBreakMode = .byWordWrapping
    label.text = "first\nsecond\nthird"
    label.numberOfLines = 0
    #expect(label.numberOfLines == 0)
    #expect(label.textLayout?.numberOfLines == 3)
    let unlimited = label.sizeThatFits(CGSize(width: 200, height: 200))
    label.numberOfLines = 1
    #expect(label.numberOfLines == 1)
    #expect(label.textLayout?.numberOfLines == 1)
    #expect(label.sizeThatFits(CGSize(width: 200, height: 200)).height < unlimited.height)
    label.numberOfLines = 2
    #expect(label.numberOfLines == 2)
    #expect(label.textLayout?.numberOfLines == 2)
}

@MainActor
@Test func lightweightMeasurementMatchesDrawingLayout() {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in }
    let decorated = NSMutableAttributedString(string: "中文 👨‍👩‍👧‍👦 wrapped text\nsecond line ", attributes: [.font: UIFont.systemFont(ofSize: 17)])
    decorated.append(NSAttributedString.po.attachmentString(with: .image(image), size: CGSize(width: 10, height: 10), alignToFont: .systemFont(ofSize: 17), verticalAlignment: .center))
    decorated.po.setTextBorder(TextBorder(fillColor: .yellow), range: decorated.allRange)
    let texts = [NSAttributedString(), NSAttributedString(string: "short"), decorated]
    for text in texts {
        for mode in [NSLineBreakMode.byWordWrapping, .byTruncatingTail, .byTruncatingHead, .byTruncatingMiddle] {
            var container = TextContainer(size: CGSize(width: 120, height: 80), insets: UIEdgeInsets(top: 2, left: 3, bottom: 4, right: 5))
            container.lineBreakMode = mode
            container.maximumNumberOfLines = 1
            container.tailTruncationToken = NSAttributedString(string: "more", attributes: [.font: UIFont.systemFont(ofSize: 17)])
            container.exclusionPaths = [UIBezierPath(rect: CGRect(x: 0, y: 0, width: 10, height: 10))]
            let layout = TextLayout(attributedString: text, container: container)
            #expect(TextLayout.measurementLayout(attributedString: text, container: container).suggestedFitsSize() == layout.suggestedFitsSize())
        }
    }
}

@MainActor
@Test func measurementRemainsCorrectAcrossColorAndGeometryChanges() {
    let label = PoLabel()
    label.numberOfLines = 0
    label.text = String(repeating: "wrapping text ", count: 20)
    let proposal = CGSize(width: 120, height: 10_000)
    let original = label.sizeThatFits(proposal)
    label.textColor = .red
    #expect(label.sizeThatFits(proposal) == original)
    label.font = .systemFont(ofSize: 30)
    #expect(label.sizeThatFits(proposal).height > original.height)
    let largeFontSize = label.sizeThatFits(proposal)
    label.textContainerInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    #expect(label.sizeThatFits(proposal).height > largeFontSize.height)
}

@Test func cachedSourceTakesPriorityOverText() throws {
    let layout = TextLayout(attributedString: NSAttributedString(string: "visible"), container: TextContainer(size: renderSize))
    let request = makeRequest(text: NSAttributedString(string: "unused"), layout: layout)
    let result = try PoTextRenderer.renderImmediately(request)
    #expect(result.layout === layout)
    #expect(result.layout?.textStorage.string == "visible")
}

@MainActor
@Test func imageAttachmentsAndHostedAttachmentsArePreparedSeparately() throws {
    let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { _ in
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    let icon = NSAttributedString.po.attachmentString(with: .image(image), size: CGSize(width: 10, height: 10), alignToFont: .systemFont(ofSize: 17), verticalAlignment: .center)
    let text = NSMutableAttributedString(attributedString: icon)
    text.append(icon)
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    text.append(NSAttributedString.po.attachmentString(with: .view(view), alignToFont: .systemFont(ofSize: 17), verticalAlignment: .center))
    let result = try PoTextRenderer.renderImmediately(makeRequest(text: text))
    #expect(result.layout?.imageAttachmentInfos.count == 2)
    #expect(result.layout?.hostedAttachmentInfos.count == 1)
    #expect(view.superview == nil)
    let host = UIView()
    result.layout?.drawAttachments(in: host, at: result.drawingPoint, size: renderSize)
    #expect(view.superview === host)
}

@Test func borderMetadataIsReadyBeforeDrawingAndPreservesRepeatedBorders() throws {
    let border = TextBorder(fillColor: .yellow)
    let text = NSMutableAttributedString(string: "one two three", attributes: [.font: UIFont.systemFont(ofSize: 17)])
    text.po.setTextBorder(border, range: NSRange(location: 0, length: 3))
    text.po.setTextBorder(border, range: NSRange(location: 8, length: 5))
    let layout = TextLayout(attributedString: text, container: TextContainer(size: CGSize(width: 300, height: 40)))
    let rects = layout.borderInfos[border]
    #expect(rects?.count == 2)
    let request = makeRequest(text: NSAttributedString(), layout: layout)
    _ = try PoTextRenderer.renderImmediately(request)
    #expect(layout.borderInfos[border] == rects)
}

@Test func sharedLayoutSerializesDrawingAndHitTesting() async throws {
    let layout = TextLayout(attributedString: NSAttributedString(string: "shared layout"), container: TextContainer(size: renderSize))
    let request = makeRequest(text: NSAttributedString(), layout: layout)
    try await withThrowingTaskGroup(of: Void.self) { group in
        for _ in 0..<20 {
            group.addTask {
                let result = try PoTextRenderer.renderImmediately(request)
                #expect(result.layout === layout)
                _ = layout.textPositionForPoint(CGPoint(x: 3, y: 3))
            }
        }
        try await group.waitForAll()
    }
}

@MainActor
@Test func cancelledWorkExitsBeforeRendering() async throws {
    let request = makeRequest(text: NSAttributedString(string: "cancelled"))
    let worker = PoTextRenderer()
    let task = Task { try await worker.render(request) }
    task.cancel()
    do {
        _ = try await task.value
        Issue.record("Cancelled rendering should throw")
    } catch is CancellationError { }
}

@Test func renderScaleComesFromTheRequest() throws {
    let result = try PoTextRenderer.renderImmediately(makeRequest(text: NSAttributedString(string: "scale"), scale: 2))
    #expect(result.image?.cgImage?.width == 200)
    #expect(result.image?.cgImage?.height == 80)
}

@Test func layoutDoesNotMutateSourceParagraphStyle() {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingMiddle
    let text = NSAttributedString(string: "source", attributes: [.paragraphStyle: style])
    _ = TextLayout(attributedString: text, container: TextContainer(size: renderSize))
    #expect(style.lineBreakMode == .byTruncatingMiddle)
}

@Test func renderingResolvesDynamicColorsUsingRequestTraits() throws {
    let color = UIColor { traits in traits.userInterfaceStyle == .dark ? .white : .black }
    let text = NSMutableAttributedString(string: "border", attributes: [.font: UIFont.systemFont(ofSize: 17)])
    text.po.setTextBorder(TextBorder(fillColor: color), range: text.allRange)
    let container = TextContainer(size: renderSize)
    let layout = TextLayout(attributedString: text, container: container)
    func render(_ style: UIUserInterfaceStyle) throws -> UIImage {
        let request = PoTextRenderRequest(text: NSAttributedString(), container: container,
                                         size: renderSize, scale: 1,
                                         traits: UITraitCollection(userInterfaceStyle: style),
                                         verticalAlignment: .center, contentsNeedFade: false,
                                         fadeForAsync: false, layout: layout)
        return try #require(PoTextRenderer.renderImmediately(request).image)
    }
    #expect(try rgbSum(render(.dark)) > rgbSum(render(.light)))
}

@MainActor
@Test func clearingContentCancelsPendingDisplay() async throws {
    let (layer, delegate) = makeLayer()
    layer.display()
    delegate.text = ""
    layer.display()
    for _ in 0..<10 { await Task.yield() }
    #expect(delegate.completedTexts == [""])
    #expect(layer.contents == nil)
}

@MainActor
@Test(arguments: [false, true])
func cancelledRedrawPreservesAttachmentTrackingUntilCommit(clearsContents: Bool) async throws {
    let label = PoLabel(frame: CGRect(origin: .zero, size: renderSize))
    label.isClearedContentsBeforeAsynchronouslyDisplay = clearsContents
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    let layer = CALayer()
    layer.bounds.size = CGSize(width: 10, height: 10)
    let text = NSMutableAttributedString(attributedString: NSAttributedString.po.attachmentString(
        with: .view(view), alignToFont: .systemFont(ofSize: 17), verticalAlignment: .center))
    text.append(NSAttributedString.po.attachmentString(
        with: .layer(layer), alignToFont: .systemFont(ofSize: 17), verticalAlignment: .center))
    label.isDisplayedAsynchronously = false
    label.attributedText = text
    label.layer.display()
    #expect(view.superview === label)
    #expect(layer.superlayer === label.layer)

    label.isDisplayedAsynchronously = true
    label.layer.display()
    label.text = "replacement"
    label.layer.display()
    // Preclearing affects bitmap and attachments together; otherwise retain
    // both until the replacement result commits.
    #expect((view.superview === label) == !clearsContents)
    #expect((layer.superlayer === label.layer) == !clearsContents)
    #expect((label.layer.contents != nil) == !clearsContents)
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(3))
    while (view.superview != nil || layer.superlayer != nil) && clock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
    #expect(view.superview == nil)
    #expect(layer.superlayer == nil)
}

private func rgbSum(_ image: UIImage) -> UInt64 {
    guard let image = image.cgImage else { return 0 }
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let context = CGContext(data: &pixels, width: image.width, height: image.height,
                            bitsPerComponent: 8, bytesPerRow: image.width * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return pixels.enumerated().reduce(0) { $0 + ($1.offset % 4 == 3 ? 0 : UInt64($1.element)) }
}

@MainActor
@Test func colorChangePreservesSizeButCannotPromoteAStaleLayout() throws {
    let label = PoLabel(frame: CGRect(x: 0, y: 0, width: 100, height: 0))
    label.displaysAsynchronously = false
    label.text = "paint only"
    let size = label.sizeThatFits(label.bounds.size)
    let measuredRevision = label._measurementLayoutRevision
    label.textColor = .red
    #expect(label._measurementLayoutFittingSize == size)
    #expect(label._measurementLayoutRevision != measuredRevision)
    #expect(label._measurementLayoutRevision == label._layoutRevision)
    #expect(label._measurementLayout == nil)
    label.bounds.size = size
    label.layer.display()
    let text = try #require(label.textLayout?.attributedString)
    #expect(text.po.foregroundColor == .red)
}

@MainActor
@Test func switchingToExplicitLayoutModeCancelsPendingCommonText() async throws {
    let label = PoLabel(frame: CGRect(origin: .zero, size: renderSize))
    label.text = "pending common text"
    label.layer.display()
    label.isIgnoredCommonProperties = true
    label.layer.display()
    for _ in 0..<10 { await Task.yield() }
    #expect(label.layer.contents == nil)
    #expect(label.textLayout == nil)
}

@MainActor
private final class RenderDelegate: NSObject, PoAsyncLayerDelegate {
    var text = "first"
    var completedTexts: [String] = []
    var lastResult: PoTextRenderResult?
    func asyncLayerPrepare(_ layer: CALayer) -> PoTextRenderRequest {
        makeRequest(text: NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 17)]))
    }
    func asyncLayerWillDisplay(_ layer: CALayer, request: PoTextRenderRequest) { MainActor.preconditionIsolated() }
    func asyncLayerDidDisplay(_ layer: CALayer, request: PoTextRenderRequest, result: PoTextRenderResult) {
        MainActor.preconditionIsolated()
        completedTexts.append(result.layout?.textStorage.string ?? "")
        lastResult = result
    }
}

private func makeRequest(text: NSAttributedString, container: TextContainer = TextContainer(size: renderSize),
                         layout: TextLayout? = nil, scale: CGFloat = 1) -> PoTextRenderRequest {
    PoTextRenderRequest(text: text, container: container, size: renderSize, scale: scale,
                        verticalAlignment: .center, contentsNeedFade: false, fadeForAsync: false,
                        layout: layout, shouldCommitLayout: true)
}

@MainActor
private func makeLayer(asynchronously: Bool = true) -> (PoAsyncLayer, RenderDelegate) {
    let layer = PoAsyncLayer()
    layer.bounds = CGRect(origin: .zero, size: renderSize)
    layer.isDisplayedAsynchronously = asynchronously
    let delegate = RenderDelegate()
    layer.delegate = delegate
    return (layer, delegate)
}

@MainActor
private func waitForDisplay(_ delegate: RenderDelegate) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(3))
    while delegate.completedTexts.isEmpty && clock.now < deadline {
        try await Task.sleep(for: .milliseconds(10))
    }
    #expect(!delegate.completedTexts.isEmpty)
}

// Read-only request inspection helpers shared by the internal regression tests.
extension PoTextRenderRequest {
    var cachedLayout: TextLayout? {
        if case .layout(let layout) = source { return layout }
        return nil
    }
    var snapshotText: NSAttributedString {
        if case .text(let snapshot) = source { return snapshot.text }
        return NSAttributedString()
    }
    var snapshotContainer: TextContainer {
        switch source {
        case .text(let snapshot): return snapshot.container
        case .layout(let layout): return layout.container
        case .empty: return TextContainer(size: size, insets: insets)
        }
    }
    var hasRenderableContent: Bool {
        if case .empty = source { return false }
        return true
    }
}
