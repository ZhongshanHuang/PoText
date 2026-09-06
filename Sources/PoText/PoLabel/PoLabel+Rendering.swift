import UIKit

// MARK: - PoAsyncLayerDelegate
extension PoLabel: PoAsyncLayerDelegate {

    func asyncLayerPrepareForRenderContext() -> PoAsyncLayerRenderContext {
        _syncContainerSizeWithBoundsIfNeeded()

        let contentsNeedFade = _state.contentsNeedFade
        _state.contentsNeedFade = false

        let container = _innerContainer
        let verticalAlignment = textVerticalAlignment
        let needsCommitLayout = !isIgnoredCommonProperties &&
            (_state.isLayoutNeedUpdate || (_innerLayout == nil && !_innerText.isEmpty))
        let fadeForAsync = isDisplayedAsynchronously && isFadedOnAsynchronouslyDisplay
        let textContainerInsets = _textContainerInsets
        let isHighlighting = _state.showHighlight && _highlight != nil && _highlightRange.location != NSNotFound

        if isHighlighting, let highlight = _highlight {
            let hiText = NSMutableAttributedString(attributedString: _highlightText ?? _innerText)
            for (key, value) in highlight.attributes {
                hiText.po.addAttribute(key, value: value, range: _highlightRange)
            }
            let highlightedLayout = isDisplayedAsynchronously ? nil : TextLayout(attributedString: hiText, container: container)
            let text = highlightedLayout == nil ? hiText : NSAttributedString()
            return PoAsyncLayerRenderContext(text: text,
                                             container: container,
                                             verticalAlignment: verticalAlignment,
                                             contentsNeedFade: contentsNeedFade,
                                             fadeForAsync: fadeForAsync,
                                             textContainerInsets: textContainerInsets,
                                             layout: highlightedLayout,
                                             shouldCommitLayout: false)
        }

        // Build the synchronous layout into the label cache before handing it
        // to the render context. A repeated prepare call can then reuse it.
        if !isDisplayedAsynchronously && !isIgnoredCommonProperties &&
            (needsCommitLayout || (_innerLayout == nil && !_innerText.isEmpty)) {
            _updateIfNeeded()
        }
        let layoutNeedUpdate = _state.isLayoutNeedUpdate
        let layout = !layoutNeedUpdate ? _innerLayout : nil
        let text = layout == nil && !isIgnoredCommonProperties ? _innerText : NSAttributedString()
        return PoAsyncLayerRenderContext(text: text,
                                         container: container,
                                         verticalAlignment: verticalAlignment,
                                         contentsNeedFade: contentsNeedFade,
                                         fadeForAsync: fadeForAsync,
                                         textContainerInsets: textContainerInsets,
                                         layout: layout,
                                         shouldCommitLayout: needsCommitLayout)
    }

    func asyncLayerWillDisplay(_ layer: CALayer, renderContext: PoAsyncLayerRenderContext) {
        layer.removeAnimation(forKey: "contents")

        guard !_attachmentViews.isEmpty || !_attachmentLayers.isEmpty else { return }

        let resolvedLayout = renderContext.layout
        let hostedAttachmentInfos = renderContext.shouldCommitLayout ? nil : resolvedLayout?.hostedAttachmentInfos
        let shouldRemoveAllAttachments = hostedAttachmentInfos == nil
        var currentAttachmentViews = Set<ObjectIdentifier>()
        var currentAttachmentLayers = Set<ObjectIdentifier>()
        if let hostedAttachmentInfos {
            currentAttachmentViews.reserveCapacity(hostedAttachmentInfos.count)
            currentAttachmentLayers.reserveCapacity(hostedAttachmentInfos.count)
            for info in hostedAttachmentInfos {
                switch info.attachment.content {
                case .image:
                    break
                case .view(let view):
                    currentAttachmentViews.insert(ObjectIdentifier(view))
                case .layer(let layer):
                    currentAttachmentLayers.insert(ObjectIdentifier(layer))
                }
            }
        }

        // if the attachment not in new layout, or we don't know the new layout currently
        // the attachment should be removed.
        for view in _attachmentViews {
            if shouldRemoveAllAttachments || !currentAttachmentViews.contains(ObjectIdentifier(view)) {
                if view.superview == self {
                    view.removeFromSuperview()
                }
            }
        }
        for attachmentLayer in _attachmentLayers {
            if shouldRemoveAllAttachments || !currentAttachmentLayers.contains(ObjectIdentifier(attachmentLayer)) {
                if attachmentLayer.superlayer == self.layer {
                    attachmentLayer.removeFromSuperlayer()
                }
            }
        }
        _attachmentViews.removeAll()
        _attachmentLayers.removeAll()
    }

    func asyncLayerDidDisplay(_ layer: CALayer, renderContext: PoAsyncLayerRenderContext, finished: Bool) {
        // if the display task is cancelled, we should clear the attachments.
        if finished == false {
            guard let layout = renderContext.layout else { return }
            for info in layout.hostedAttachmentInfos {
                switch info.attachment.content {
                case .image:
                    break
                case .view(let uiView):
                    if uiView.superview == (layer.delegate as? UIView) { uiView.removeFromSuperview() }
                case .layer(let cALayer):
                    if cALayer.superlayer == layer { cALayer.removeFromSuperlayer() }
                }
            }
            return
        }

        layer.removeAnimation(forKey: "contents")

        let resolvedLayout = renderContext.layout

        if renderContext.shouldCommitLayout {
            _innerLayout = resolvedLayout
            _state.isLayoutNeedUpdate = false
        }

        if let layout = resolvedLayout, !layout.hostedAttachmentInfos.isEmpty {
            let size = layer.bounds.size
            let point = renderContext.drawingPoint(for: size)
            let drawnAttachments = layout.drawAttachments(in: self, at: point, size: size)
            if !drawnAttachments.views.isEmpty {
                _attachmentViews.append(contentsOf: drawnAttachments.views)
            }
            if !drawnAttachments.layers.isEmpty {
                _attachmentLayers.append(contentsOf: drawnAttachments.layers)
            }
        }

        if renderContext.contentsNeedFade {
            let transition = CATransition()
            transition.duration = Constant.highlightFadeDuration
            transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
            transition.type = .fade
            layer.add(transition, forKey: "contents")
        } else if renderContext.fadeForAsync {
            let transition = CATransition()
            transition.duration = Constant.asyncFadeDuration
            transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
            transition.type = .fade
            layer.add(transition, forKey: "contents")
        }
    }

}
