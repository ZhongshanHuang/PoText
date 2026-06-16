//
//  ForegroundBorderViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class ForegroundBorderViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        version2()
    }
    
    private func version1() {
        let text = makeText()
        
        let label = PoLabel(text)
            .lines(0)
            .alignment(.center)
            .verticalAlignment(.center)
        label.frame = view.bounds
        view.addSubview(label)
    }
    
    private func version2() {
        let text = makeText()
        
        let label = PoLabel(text)
            .lines(0)
            .alignment(.center)
            .verticalAlignment(.center)
        label.frame = view.bounds
        view.addSubview(label)
    }

    private func makeText() -> NSAttributedString {
        let examples: [(text: String, lineStyle: TextLineStyle, lineWidth: CGFloat, color: UIColor)] = [
            ("Single", .single, 2, UIColor(hex: "#fa3f39")),
            ("Double", .double, 1, UIColor(hex: "#f48f25")),
            ("Single&PatterDot", [.single, .patternDot], 3, UIColor(hex: "#f1c02c")),
            ("Double&PatternDash", [.double, .patternDash], 1, UIColor(hex: "#54bc2e")),
            ("Single&PatternDashDot", [.single, .patternDashDot], 3, UIColor(hex: "#012060")),
            ("Single&PatternDashDotDot", [.single, .patternDashDotDot], 3, UIColor(hex: "#29a9ee")),
            ("Single&PatternCircleDot", [.single, .patternCircleDot], 3, UIColor(hex: "#c171d8"))
        ]

        return NSAttributedString(style: PoTextStyle(font: .systemFont(ofSize: 30))) {
            for (index, example) in examples.enumerated() {
                PoText(example.text)
                    .foregroundColor(example.color)
                    .textBorder(TextBorder(lineStyle: example.lineStyle,
                                           lineWidth: example.lineWidth,
                                           strokeColor: example.color,
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2)))

                if index < examples.count - 1 {
                    padding
                    padding
                    padding
                }
            }
        }
    }
    
}
