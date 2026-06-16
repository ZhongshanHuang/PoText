//
//  KernViewController.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class KernViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        version2()
    }
    
    private func version1() {
        let text = makeText()
        
        let label = PoLabel(text, frame: CGRect(x: 0, y: 0, width: view.frame.width - 20, height: 0))
            .lines(0)
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }
    
    private func version2() {
        let text = makeText()
        
        let label = PoLabel(text, frame: CGRect(x: 0, y: 0, width: view.frame.width - 20, height: 0))
            .lines(0)
        label.sizeToFit()
        label.center = view.center
        view.addSubview(label)
    }

    private func makeText() -> NSAttributedString {
        NSAttributedString(style: PoTextStyle(font: .systemFont(ofSize: 30))) {
            PoText("Typography Kern -2").kern(-2)
            padding
            PoText("Typography Kern 0").kern(0)
            padding
            PoText("Typography Kern 2").kern(2)
        }
    }
}
