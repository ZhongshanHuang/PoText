//
//  BorderViewController.swift
//  KitDemo
//
//  Created by 黄山哥 on 2019/8/25.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class BackgroundBorderViewController: ExampleBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        version2()
    }
    
    private func version1() {
        let text = makeText(lineSpacing: 10)

        let label = PoLabel(text).lines(0)
        label.frame = view.bounds
        view.addSubview(label)
    }
    
    private func version2() {
        let text = makeText(lineSpacing: 30)

        let label = PoLabel(text).lines(0)
        label.frame = view.bounds
        view.addSubview(label)
    }

    private func makeText(lineSpacing: CGFloat) -> NSAttributedString {
        let tags = ["red", "orange", "yellow", "green", "cyan", "blue", "purple"]
        let tagStrokeColors = [UIColor.purple,
                               UIColor.blue,
                               UIColor.cyan,
                               UIColor.green,
                               UIColor.yellow,
                               UIColor.orange,
                               UIColor.red]
        let tagFillColors = [UIColor.red,
                             UIColor.orange,
                             UIColor.yellow,
                             UIColor.green,
                             UIColor.cyan,
                             UIColor.blue,
                             UIColor.purple]
        let font = UIFont.boldSystemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        let style = PoTextStyle().paragraphStyle(paragraphStyle)
        
        return NSAttributedString(style: style) {
            for (idx, tag) in tags.enumerated() {
                "   "
                
                PoText(tag)
                    .font(font)
                    .foregroundColor(.white)
                    .textBorder(TextBorder(lineStyle: .single, 
                                           lineWidth: 1,
                                           strokeColor: tagStrokeColors[idx],
                                           lineJoin: .bevel,
                                           fillColor: tagFillColors[idx],
                                           cornerRadius: 10,
                                           insets: UIEdgeInsets(top: -2, left: -5.5, bottom: -2, right: -8)))
                
                
                "   "
            }
        }
    }

}
