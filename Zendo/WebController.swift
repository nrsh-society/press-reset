//
//  WebController.swift
//  Zendo
//
//  Created by Douglas Purdy on 4/4/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Foundation
import HealthKit

class WebController : UIViewController {
    
    @IBOutlet var Url : String?
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        
        let url = URL(string: self.Url!)
        webView.loadRequest(URLRequest(url: url!))
        
    }
    
    @IBAction func actionClick(_ sender: Any) {
        
        let url = URL(string: self.Url!)
        
        let vc = UIActivityViewController(activityItems: [url as Any], applicationActivities: [])
        
        vc.excludedActivityTypes = [
            UIActivityType.assignToContact,
            UIActivityType.saveToCameraRoll,
            UIActivityType.postToFlickr,
            UIActivityType.postToVimeo,
            UIActivityType.postToTencentWeibo,
            UIActivityType.postToTwitter,
            UIActivityType.postToFacebook,
            UIActivityType.openInIBooks
        ]
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func doneClick(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
