//
//  ShadowViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class ShadowViewController: ExampleBaseViewController {

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
        PoText("Core Text Shadow")
            .font(.systemFont(ofSize: 30))
            .foregroundColor(.white)
            .shadow(color: .gray, offset: CGSize(width: 0, height: 2), blur: 1.5)
            .attributedString
    }

}
