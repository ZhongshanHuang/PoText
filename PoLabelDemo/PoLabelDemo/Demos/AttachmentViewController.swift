//
//  AttachmentViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/26.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class AttachmentViewController: ExampleBaseViewController {

    var label: PoLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        version2()
    }
    
    private func version1() {
        let font = UIFont.systemFont(ofSize: 16)
        let text = makeText(font: font)
        
        label = PoLabel(text)
            .asyncDisplay(false)
            .lines(0)
            .verticalAlignment(.top)
        label.size = CGSize(width: 300, height: 260)
        label.center = view.center
        addSeeMoreButton()
        view.addSubview(label)
        
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor(red: 0, green: 0.436, blue: 1, alpha: 1).cgColor
        
        let dot = newDotView()
        dot.center = CGPoint(x: label.width, y: label.height)
        dot.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        label.addSubview(dot)
        
        let gesture = GestureRecognizer()
        gesture.action = { [weak self] (gesture, state) in
            guard let self = self else { return }
            if state != .moved { return }
            let width = gesture.currentPoint.x
            let height = gesture.currentPoint.y
            self.label.width = width < 30 ? 30 : width
            self.label.height = height < 30 ? 30 : height
        }
        gesture.delegate = self
        label.addGestureRecognizer(gesture)
    }
    
    private func version2() {
        let font = UIFont.systemFont(ofSize: 16)
        let text = makeText(font: font)
                        
        label = PoLabel(text)
            .asyncDisplay(false)
            .lines(0)
            .verticalAlignment(.top)
        label.size = CGSize(width: 300, height: 260)
        label.center = view.center
        addSeeMoreButton()
        view.addSubview(label)
        
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor(red: 0, green: 0.436, blue: 1, alpha: 1).cgColor
        
        let dot = newDotView()
        dot.center = CGPoint(x: label.width, y: label.height)
        dot.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        label.addSubview(dot)
        
        let gesture = GestureRecognizer()
        gesture.action = { [weak self] (gesture, state) in
            guard let self = self else { return }
            if state != .moved { return }
            let width = gesture.currentPoint.x
            let height = gesture.currentPoint.y
            self.label.width = width < 30 ? 30 : width
            self.label.height = height < 30 ? 30 : height
        }
        gesture.delegate = self
        label.addGestureRecognizer(gesture)
    }
    
    private func addSeeMoreButton() {
        let text = NSAttributedString(style: PoTextStyle(font: self.label.font)) {
            PoText("\u{2026}")
                .foregroundColor(.black)
            PoText("more")
                .foregroundColor(UIColor(red: 0, green: 0.449, blue: 1, alpha: 1))
                .onTap(highlightForegroundColor: UIColor(red: 0.578, green: 0.79, blue: 1, alpha: 1)) { [weak self] _ in
                    self?.label.sizeToFit()
                }
        }

        let seeMore = PoLabel(text)
        seeMore.sizeToFit()
        let truncationToken = PoAttachment(seeMore, size: seeMore.size, alignToFont: self.label.font, verticalAlignment: .center).attributedString
        label.tailTruncationToken = truncationToken
    }

    private func makeText(font: UIFont) -> NSAttributedString {
        NSAttributedString(style: PoTextStyle(font: font)) {
            "This is UIImage attachment:"
            PoAttachment(UIImage(named: "dribbble64_imageio")!, alignToFont: font, verticalAlignment: .top)

            "\n"

            "This is UIView attachment:"

            let switcher = makeSwitch()
            PoAttachment(switcher, size: switcher.frame.size, alignToFont: font, verticalAlignment: .center)

            "\n"

            "This is Animated Image attachment:"

            for name in ["001@2x", "022@2x", "019@2x", "056@2x", "085@2x"] {
                let image = UIImage(contentsOfFile: Bundle.main.path(forResource: name, ofType: "gif")!)
                let imageView = UIImageView(image: image)
                PoAttachment(imageView, size: imageView.size, alignToFont: font, verticalAlignment: .bottom)
            }
        }
    }

    private func makeSwitch() -> UISwitch {
        let switcher = UISwitch()
        switcher.sizeToFit()
        return switcher
    }
    
    private func newDotView() -> UIView {
        let view = UIView()
        view.size = CGSize(width: 50, height: 50)
        
        let dot = UIView()
        dot.size = CGSize(width: 10, height: 10)
        dot.backgroundColor = UIColor(red: 0, green: 0.463, blue: 1, alpha: 1)
        dot.clipsToBounds = true
        dot.layer.cornerRadius = dot.width / 2
        dot.center = CGPoint(x: view.width / 2, y: view.height / 2)
        view.addSubview(dot)
        
        return view
    }
    
}

extension AttachmentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(in: label)
        if p.x < label.width - 40 { return false }
        if p.y < label.height - 40 { return false }
        return true
    }
}
