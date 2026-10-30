# PoText

Attributed label based on TextKit, with a Swift result-builder API that keeps
Foundation's `NSAttributedString` as the output type.

Requires iOS 15 or later.

See [rendering architecture](Docs/Rendering.md) for concurrency ownership,
measurement reuse, attachment sizing, and feature1 performance comparisons.

## API Style

Use the named initializers when creating a label and configure it with UIKit
property names when that reads better for your code:

```swift
let label = PoLabel(text: "Hello")
    .numberOfLines(0)
    .textAlignment(.center)
    .textContainerInsets(.init(top: 4, left: 8, bottom: 4, right: 8))
```

For several UIKit-style changes, `configure` coalesces rendering and
intrinsic-size invalidation into one update:

```swift
let label = PoLabel().configure { label in
    label.text = "Hello"
    label.numberOfLines = 0
    label.textAlignment = .center
}
```

Use `PoText` for text fragments, `PoTextStyle` for reusable styles, and
`PoLabel` for display. UIKit property names are the preferred configuration
spelling; the shorter aliases remain available for compatibility.

`PoText` and `PoAttributeContainer` are value types. Styling or appending a
value returns a new value, so a reusable base fragment can safely be shared:

```swift
let emphasis = PoTextStyle.body.foregroundColor(.systemRed)
let text = PoText(string: "Important", style: emphasis)
```

Common dynamic-type styles are available as `PoTextStyle.body`,
`PoTextStyle.headline`, and `PoTextStyle.caption`.

## Quick Start

```swift
let bodyStyle = PoTextStyle(font: .systemFont(ofSize: 16), color: .label)

let label = PoLabel(style: bodyStyle) {
    "Hello "
    PoText("PoText")
        .foregroundColor(.systemRed)
        .font(.boldSystemFont(ofSize: 18))
    "!"
}
.numberOfLines(0)
.textAlignment(.center)
```

`style:` and `attributeContainer:` are applied as base attributes. Local
attributes keep priority by default.
Use `mergePolicy: .overrideLocal` when the base style should replace local attributes.
Existing code that relied on `attributeContainer:` overriding local attributes
should explicitly pass `.overrideLocal`.

The builder also accepts `String`, `Substring`, optional text fragments,
`NSAttributedString`, and Swift's native `AttributedString` directly. Use
`swiftAttributedString` when a Foundation value needs to cross into Swift's
native attributed-string APIs.

For typed custom attributes, conform a key to `PoAttributedStringKey`:

```swift
struct BadgeKey: PoAttributedStringKey {
    typealias Value = String
    static let name = NSAttributedString.Key("Badge")
}

var attributes = PoAttributeContainer()
attributes[BadgeKey.self] = "new"
let text = NSAttributedString(attributeContainer: attributes) { "Inbox" }
```

## Highlights

Appending a plain `String` preserves visual styling but clears inherited
actions, links, attachments, and backed strings from the appended range.
Assigning `PoLabel.text` also clears these attributes, including when the new
string equals the previous text.

```swift
let text = NSAttributedString {
    "Tap "
    PoText.link("here") { context in
        print(context.selectedString ?? "")
    }
}
```

## Attachments

```swift
let imageText = NSAttributedString {
    "Icon "
    PoText.attachment(UIImage(named: "icon")!, size: CGSize(width: 16, height: 16))
}
```

Fit native controls before creating their attachments, and omit `size:` to
reserve their current bounds. Control dimensions can change between iOS versions;
a historical fixed size may reserve less space than the control actually uses.

```swift
let toggle = UISwitch()
toggle.sizeToFit()
let controlText = PoText.attachment(toggle, alignToFont: .systemFont(ofSize: 16))
```

The older global `PoLink`, `PoAttachment`, and `PoTag` functions remain
available for source compatibility and are deprecated in favor of the
corresponding `PoText` factory methods.
