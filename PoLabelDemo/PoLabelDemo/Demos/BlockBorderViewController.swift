//
//  BlockBorderViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class BlockBorderViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        version2()
    }
    
    private func version1() {
        let text = makeText()
        
        let label = PoLabel(text).lines(0)
        label.frame = view.bounds
        label.backgroundColor = UIColor(white: 0.134, alpha: 1)
        view.addSubview(label)
    }
    
    private func version2() {
        let text = makeText()
        
        let label = PoLabel(text).lines(0)
        label.frame = view.bounds
        label.backgroundColor = UIColor(white: 0.134, alpha: 1)
        view.addSubview(label)
    }

    private func makeText() -> NSAttributedString {
        NSAttributedString(style: PoTextStyle().foregroundColor(.white)) {
            "Here is some code:\n\n\t"

            PoText("if(a){\n\t\tif(b){\n\t\t\tif(c){\n\t\t\t\tprintf(\"haha\");\n\t\t\t}\n\t\t}\n\t}\n")
                .textBlockBorder(TextBorder(fillColor: UIColor(white: 0.82, alpha: 0.13),
                                            cornerRadius: 2,
                                            insets: UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)))
        }
    }

}
