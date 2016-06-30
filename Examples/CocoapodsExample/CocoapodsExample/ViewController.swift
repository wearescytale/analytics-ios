//
//  ViewController.swift
//  CocoapodsExample
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Analytics.track("Cocoapods Example Main View Load")
        Analytics.flush()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func fireEvent(sender: AnyObject) {
        Analytics.track("Cocoapods Example Fire Event")
        Analytics.flush()
    }

}

