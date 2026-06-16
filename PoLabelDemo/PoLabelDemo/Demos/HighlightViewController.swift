//
//  HighlightViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class HighlightViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
//        version1()
        version2()
    }
    
    func version1() {
        let text = makeText()
        
        let label = PoLabel(text)
            .lines(0)
            .alignment(.center)
            .verticalAlignment(.center)
        label.frame = view.bounds
        view.addSubview(label)
    }
    
    func version2() {
        let text = makeText()
        
        let label = PoLabel(text)
            .lines(0)
            .alignment(.center)
            .verticalAlignment(.center)
        label.frame = view.bounds
        view.addSubview(label)
    }

    private func makeText() -> NSAttributedString {
        let style = PoTextStyle(font: .systemFont(ofSize: 30), color: .blue)
            .underline(.single, color: .blue)

        return NSAttributedString(style: style) {
            PoText("link1")
                .onTap(highlightBackgroundColor: .red) { _ in
                    print("link1 tap")
                }
            "-"
            PoText("link2")
                .onTap(highlightForegroundColor: .yellow) { _ in
                    print("link2 tap")
                }
        }
    }

}
