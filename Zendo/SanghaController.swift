//
//  SanghaController.swift
//  Zendo
//
//  Created by Douglas Purdy on 4/4/18.
//  Copyright © 2018 zenbf. All rights reserved.
//
import UIKit
import Foundation

class SanghaController : UIViewController {
    
 @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        webView.loadRequest(URLRequest(url: URL(string: "http://zenbf.org/sangha")!))
    }
    
    @IBAction func actionClick(_ sender: Any) {
        
    }
    
    @IBAction func doneClick(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
