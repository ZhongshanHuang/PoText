//
//  ExampleBaseViewController.swift
//  KitDemo
//
//  Created by iOSer on 2019/8/27.
//  Copyright © 2019 黄中山. All rights reserved.
//

import UIKit
import PoText

class ExampleBaseViewController: UIViewController {
    
    var padding: NSAttributedString {
        PoText("\n")
            .font(.systemFont(ofSize: 4))
            .attributedString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.backgroundColor = .systemBackground
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
