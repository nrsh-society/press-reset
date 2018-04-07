//
//  BuddhaController.swift
//  Zendo
//
//  Created by Douglas Purdy on 4/4/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Foundation
import HealthKit

class BuddhaController : UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        webView.loadRequest(URLRequest(url: URL(string: "http://zenbf.org/buddha")!))
    }
    
    @IBAction func actionClick(_ sender: Any) {
        exportAll()
    }
    
    @IBAction func doneClick(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func exportAll() {
        
        var samples = [[String:Any]]()
        
        let hkPredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        
        
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query, results, error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.sync() {
                    
                    samples = results!.map { dictionary in
                        var dict: [String: String] = [:]
                        dictionary.metadata!.forEach { (key, value) in dict[key] = "\(value)" }
                        return dict
                    }
                    
                    let fileName = "zazen.json"
                    let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                    
                    let outputStream = OutputStream(url: path!, append: false)
                    
                    outputStream?.open()
                    
                    JSONSerialization.writeJSONObject(
                        samples,
                        to: outputStream!,
                        options: JSONSerialization.WritingOptions.prettyPrinted,
                        error: nil)
                    
                    outputStream?.close()
                    
                    let vc = UIActivityViewController(activityItems: [path as Any], applicationActivities: [])
                    
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
                    
                };
            }
            
        });
        
        HKHealthStore().execute(hkQuery)

    }
}
