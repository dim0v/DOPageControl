//
//  ViewController.swift
//  DOPageControl
//
//  Created by Dmytro Ovcharenko on 07/28/2015.
//  Copyright (c) 2015 Dmytro Ovcharenko. All rights reserved.
//

import UIKit
import DOPageControl

class ViewController: UIViewController {

    @IBOutlet weak var pageControl: PageControl!
    
    @IBAction func pageChanged(_ sender: PageControl) {
        print("Page changed: \(sender.currentPage)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControl.colorMapping = [UIColor.red, UIColor.green, UIColor.blue, UIColor.red];
    }
}

