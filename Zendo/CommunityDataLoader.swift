//
//  CommunityDataLoader.swift
//  Zendo
//
//  Created by Douglas Purdy on 6/9/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation

class CommunityDataLoader {
    
    static let instance = CommunityDataLoader()
    static let urlString = URL(string: "http://zenbf.org/community_baseline")
    static var values : [String: Any]?
    static var task: URLSessionDataTask?
    
    static func load()
    {
        if let url = urlString {
            self.task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error as Any)
                } else {
                    if let usableData = data {
                        self.values = try! JSONSerialization.jsonObject(with: usableData, options: []) as! [String : Any]
                    }
                }
            }
            task!.resume()
        }
    }
    
    static func get(measure: String, at: Double) -> Double {
        
        var value = 0.0
    
        let key = measure.contains("heart") ? "hr" : measure
    
        if let communityValues = values {
            
            if let communityValue = communityValues[key]
            {
                value = communityValue as! Double
            }
        }
        
        return value
    }
}


