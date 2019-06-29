//
//  Settings.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation


class Settings: NSObject {

    static let defaults = UserDefaults.standard
    
    static let SHARED_SECRET = "80653a3a2e33453c9e69f7d2da8945eb"
//   static let SHARED_SECRET = "e929eeee2144466197cd844b370fbffb" // test
    
    static var didFinishCommunitySignup: Bool {
        set {
            defaults.set(newValue, forKey: "runonce")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "runonce")
        }
    }

    static var skippedCommunitySignup: Bool {
        set {
            defaults.set(newValue, forKey: "skippedCommunitySignup")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "skippedCommunitySignup")
        }
    }
    
    static var fullName: String? {
        set {
            defaults.set(newValue, forKey: "fullName")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "fullName")
        }
    }
    
    static var email: String? {
        set {
            defaults.set(newValue?.trimmingCharacters(in: CharacterSet.whitespaces), forKey: "email")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "email")?.trimmingCharacters(in: CharacterSet.whitespaces)
            }
        }
    
    static var requestedNotificationPermission: Bool {
        set {
            defaults.set(newValue, forKey: "requestedNotificationPermission")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "requestedNotificationPermission")
        }
    }
    
    static var isSubscriptionAvailability: Bool {
        set {
            defaults.set(newValue, forKey: "isSubscriptionAvailability")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isSubscriptionAvailability")
        }
    }
    
    static var isSetTrial: Bool {
        set {
            defaults.set(newValue, forKey: "isSetTrial")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isSetTrial")
        }
    }
    
    static var isTrial: Bool {
        set {
            defaults.set(newValue, forKey: "isTrial")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isTrial")
        }
    }
    
    static var startTrialDateStr: String? {
        set {
            defaults.set(newValue, forKey: "startTrialDateStr")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "startTrialDateStr")
        }
    }
    
    static var expiresDateStr: String? {
        set {
            defaults.set(newValue, forKey: "expiresDateStr")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "expiresDateStr")
        }
    }
    
    static var expiresDate: Date? {
        if let str = expiresDateStr, let date = str.dateFromUTCSubscriptionString {
            return date
        }
        return nil
    }
    
    static var startTrialDate: Date? {
        if let str = startTrialDateStr, let date = str.dateFromUTCSubscriptionString {
            return date
        }
        return nil
    }
    
    static func checkSubscriptionAvailability(_ completionHandler: ((Bool, Bool) -> ())? = nil) {
        
       // completionHandler?(true, false)
        //return
        
        if isTrial && !isSubscriptionAvailability {
            completionHandler?(false, true)
            return
        }
        
        if !isTrial {
            if let date = expiresDate, date > Date() {
                completionHandler?(true, false)
            } else {
                checkSubscription { subscription, trial in
                    completionHandler?(subscription, trial)
                }
            }
        }
        
    }
        
    static func checkSubscription(_ completionHandler: ((Bool, Bool) -> ())? = nil) {
        guard let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
                completionHandler?(false, false)
                return
        }
        
       // let appleServer = receiptUrl.lastPathComponent == "sandboxReceipt" ? "sandbox" : "buy"
        
        let prodServer = "https://buy.itunes.apple.com/verifyReceipt"
        let testServer = "https://sandbox.itunes.apple.com/verifyReceipt"
        
        var request = URLRequest(url: URL(string: prodServer)! )
        request.httpMethod = "POST"
        
        let httpBody = [
            "receipt-data": receipt,
            "password": SHARED_SECRET
        ]
        
        if let json = try? JSONSerialization.data(withJSONObject: httpBody, options: []) {
            request.httpBody = json
        } else {
            completionHandler?(false, false)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, error == nil {
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers])
                    as? [String: Any],
                    let lastReceipt = json?["latest_receipt_info"] as? [[String: Any]],
                    let expiresDate = lastReceipt.last?["expires_date"] as? String else {
                        print("error trying to convert data to JSON")
                        completionHandler?(false, false)
                        return
                }
                
                self.expiresDateStr = expiresDate
                
                if let date = expiresDate.dateFromUTCSubscriptionString {
                    isSubscriptionAvailability = date > Date()
                    completionHandler?(date > Date(), false)
                }
                
            }
            
            else if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 21007
            {
                
                let testServer = "https://sandbox.itunes.apple.com/verifyReceipt"
                
                var request = URLRequest(url: URL(string: testServer)! )
                request.httpMethod = "POST"
                
                let httpBody = [
                    "receipt-data": receipt,
                    "password": SHARED_SECRET
                ]
                
                if let json = try? JSONSerialization.data(withJSONObject: httpBody, options: []) {
                    request.httpBody = json
                } else {
                    completionHandler?(false, false)
                }
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data, error == nil {
                        
                        guard let json = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers])
                            as? [String: Any],
                            let lastReceipt = json?["latest_receipt_info"] as? [[String: Any]],
                            let expiresDate = lastReceipt.last?["expires_date"] as? String else {
                                print("error trying to convert data to JSON")
                                completionHandler?(false, false)
                                return
                        }
                        
                        self.expiresDateStr = expiresDate
                        
                        if let date = expiresDate.dateFromUTCSubscriptionString {
                            isSubscriptionAvailability = date > Date()
                            completionHandler?(date > Date(), false)
                        }
                        
                    }
            }
            }
            
            else {
                completionHandler?(false, false)
            }
            }.resume()
    }
    
    static var isWatchConnected: Bool {
        set {
            defaults.set(newValue, forKey: "isWatchConnected")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isWatchConnected")
        }
    }
    
    static var connectedDate: Date? {
        set {
            defaults.set(newValue, forKey: "connectedDate")
            defaults.synchronize()
        }
        get {
            return defaults.object(forKey: "connectedDate") as? Date
        }
    }
    
    static var lastUploadDateStr: String? {
        set {
            defaults.set(newValue, forKey: "lastUploadDateStr")
            defaults.synchronize()
        }
        get {
            return defaults.string(forKey: "lastUploadDateStr")
        }
    }
    
    static var lastUploadDate: Date? {
        if let str = lastUploadDateStr, let date = str.dateFromUTCSubscriptionString {
            return date
        }
        return nil
    }
    
}
