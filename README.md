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
Use `mergePolicy: .overrideLocal` when the base style should replace local attributes.

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
