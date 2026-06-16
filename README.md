# PoText

Attributed label based on TextKit.

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

## Highlights

```swift
let text = NSAttributedString {
    "Tap "
    PoLink("here") { context in
        print(context.selectedString ?? "")
    }
}
```

## Attachments

```swift
let imageText = NSAttributedString {
    "Icon "
    PoAttachment(UIImage(named: "icon")!, size: CGSize(width: 16, height: 16))
}
```
