//
//  OptIn.swift
//  Zendo
//
//  Created by Yuen, Billy on 5/24/19.
//  Copyright © 2019 zenbf. All rights reserved.
//

import Foundation

public class OptIn {
    
    static let instance = OptIn()
    static let urlString = URL(string: "https://s3.amazonaws.com/zenbf.org/opt-in.json")
    static var values : [String: Any]?
    static var task: URLSessionDataTask?
    
    class func uploadSessions() {
        if (match()) {
            //TODO:
            //0.  Test with your own email first. (Use info@zenbf.org for production.)
            //1.  Call the GetWorkouts(since:) in ZBHealthKit.swift
            //2.  Email one session at a time.  (sample code in UIActivityViewController.swift)
            //3.  Persist the date of the last uploaded in Settings.lastUploadDate
        } else {
            print("not match")
        }
        
    }
    
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
    
    static func match() -> Bool {
        
        var value = false
        
        if let emailList = values {
            
            if let email = Settings.email {
                if let optInFlag = emailList[email] {
                    value = optInFlag as! Bool
                }
            }
        }
        return value;
    }
}
