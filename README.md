# PoText

Attributed label based on TextKit, with a Swift result-builder API that keeps
Foundation's `NSAttributedString` as the output type.

Requires iOS 15 or later.

## API Style

Use the named initializers when creating a label and configure it with UIKit
property names when that reads better for your code:

```swift
let label = PoLabel(text: "Hello")
    .numberOfLines(0)
    .textAlignment(.center)
    .textInsets(.init(top: 4, left: 8, bottom: 4, right: 8))
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
.lines(0)
.alignment(.center)
```

`style:` is applied as a base style. Local attributes keep priority by default.
Use `mergePolicy: .overrideLocal` when the base style should replace local attributes.

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

The older global `PoLink`, `PoAttachment`, and `PoTag` functions remain
available for source compatibility and are deprecated in favor of the
corresponding `PoText` factory methods.
