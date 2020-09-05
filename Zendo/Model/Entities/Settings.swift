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
    
    //#todo(security): seems bad? #eng can we make this come from a zendo.tools server?
    static let SHARED_SECRET = "80653a3a2e33453c9e69f7d2da8945eb"
    
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
    
    static var nameMovesense: String? {
        set {
             defaults.set(newValue, forKey: "nameMovesense")
                       defaults.synchronize()
        }
        get {
             return defaults.string(forKey: "nameMovesense")
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
    
    static var isTrial: Bool {
        set {
            defaults.set(newValue, forKey: "isTrial")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isTrial")
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
    
    static func checkSubscriptionAvailability(_ completionHandler: ((_ subscription: Bool) -> ())? = nil) {
        
        if let date = expiresDate, date > Date() {
            completionHandler?(true)
        } else {
            checkSubscription { subscription in
                completionHandler?(subscription)
            }
        }
                
    }
    
    //todo(refactor): this should be in #subscription not #settings
    static func checkSubscription(_ completionHandler: ((_ subscription: Bool) -> ())? = nil) {
        
        let prodServer = "https://buy.itunes.apple.com/verifyReceipt"
//        let testServer = "https://sandbox.itunes.apple.com/verifyReceipt"
        
        guard let receiptUrl = Bundle.main.appStoreReceiptURL,
            let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString(),
            let url = URL(string: prodServer) else {
                completionHandler?(false)
                return
        }
        
//         let appleServer = receiptUrl.lastPathComponent == "sandboxReceipt" ? "sandbox" : "buy"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let httpBody = [
            "receipt-data": receipt,
            "password": SHARED_SECRET
        ]
        
        if let json = try? JSONSerialization.data(withJSONObject: httpBody, options: []) {
            request.httpBody = json
        } else {
            completionHandler?(false)
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, error == nil {
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? [String: Any],
                    let lastReceipt = json?["latest_receipt_info"] as? [[String: Any]],
                    let expiresDate = lastReceipt.last?["expires_date"] as? String,
                    let isTrialPeriod = lastReceipt.last?["is_trial_period"] as? String else {
                        print("error trying to convert data to JSON")
                        completionHandler?(true)
                        return
                }
                
                self.expiresDateStr = expiresDate
                self.isTrial = isTrialPeriod.boolValue
                
                if let date = expiresDate.dateFromUTCSubscriptionString {
                    completionHandler?(date > Date())
                }
                
            } else if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 21007 {
                
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
                    completionHandler?(true)
                }
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data, error == nil {
                        
                        guard let json = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers])
                            as? [String: Any],
                            let lastReceipt = json?["latest_receipt_info"] as? [[String: Any]],
                            let expiresDate = lastReceipt.last?["expires_date"] as? String,
                            let isTrialPeriod = lastReceipt.last?["is_trial_period"] as? String else {
                                print("error trying to convert data to JSON")
                                completionHandler?(false)
                                return
                        }
                        
                        self.expiresDateStr = expiresDate
                        self.isTrial = isTrialPeriod.boolValue
                        
                        if let date = expiresDate.dateFromUTCSubscriptionString {
                            completionHandler?(date > Date())
                        }
                        
                    }
                }
            } else {
                completionHandler?(true)
            }
        }.resume()
    }
    
    static var isZensorConnected: Bool {
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
    
    static var isUploadDate: Bool {
        set {
            defaults.set(newValue, forKey: "isUploadDate")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "isUploadDate")
        }
    }
    
}


extension String {

    var boolValue: Bool {
        return (self as NSString).boolValue
    }
    
}
