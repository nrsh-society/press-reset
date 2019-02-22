//
//  Settings.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation


class Settings  {

    static let defaults = UserDefaults.standard
    
    static let SHARED_SECRET = "80653a3a2e33453c9e69f7d2da8945eb"
   

    static var isRunOnce: Bool {
        set {
            defaults.set(newValue, forKey: "runonce")
            defaults.synchronize()
        }
        get {
            return defaults.bool(forKey: "runonce")
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
        if let str = expiresDateStr, let date = str.dateFromUTCString {
            return date
        }
        return nil
    }
    
    static var startTrialDate: Date? {
        if let str = startTrialDateStr, let date = str.dateFromUTCString {
            return date
        }
        return nil
    }
    
    static func checkSubscriptionAvailability(_ completionHandler: ((Bool, Bool) -> ())? = nil) {
        
        if isTrial && !isSubscriptionAvailability {
            completionHandler?(false, true)
            return
        }
        
        if !isTrial {
            if let date = expiresDate, date > Date() {
                completionHandler?(true, false)
            } else {
                
                guard let receiptUrl = Bundle.main.appStoreReceiptURL,
                    let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
                        completionHandler?(false, false)
                        return
                }
                
                let appleServer = receiptUrl.lastPathComponent == "sandboxReceipt" ? "sandbox" : "buy"
                
                let stringURL = "https://\(appleServer).itunes.apple.com/verifyReceipt"
                
                var request = URLRequest(url: URL(string: stringURL)! )
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
                        
                        if let date = expiresDate.dateFromUTCString {
                            isSubscriptionAvailability = date > Date()
                            completionHandler?(date > Date(), false)
                        }
                        
                    } else {
                        completionHandler?(false, false)
                    }
                    }.resume()
                
            }
        }
        
        
    }
    
    
}
