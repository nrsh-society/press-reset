//
//  WatchSessionManager.swift
//  Zendo
//
//  Created by Anton Pavlov on 16/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchConnectivity
import Firebase
import FirebaseDatabase
import FBSDKCoreKit
import FacebookCore

class WatchSessionManager: NSObject {
    
    static let sharedManager = WatchSessionManager()
    
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    private var validSession: WCSession? {
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }

    func startSession() {
        session?.delegate = self
        session?.activate()
    }
}

extension WatchSessionManager: WCSessionDelegate {
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation did complete \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void)
    {
        print(message)
        
        if let message = message as? [String: String]
        {
            
            if message["watch"] == "reload"
            {
                NotificationCenter.default.post(name: .reloadActivity, object: nil)
                NotificationCenter.default.post(name: .reloadOverview, object: nil)
            }
            else if message["watch"] == "mixpanel"
            {
                if let email = Settings.email,
                let name = Settings.fullName
                {
                    replyHandler(["email": email, "name": name])
                }
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "watch_identity"))
            }
            else if message["watch"] == "registerNotifications"
            {
                DispatchQueue.main.async
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "watch_notification"))
            }
            else if message["watch"] == "subscribe"
            {
                Settings.checkSubscriptionAvailability { subscribe in
                    replyHandler(["isSubscribe": subscribe, "isTrial": Settings.isTrial])
                }
            }
            else if message["watch"] == "present"
            {
                let vcSub = SubscriptionViewController.loadFromStoryboard()
                if let vc = UIApplication.shared.keyWindow?.topViewController, !vc.isKind(of: SubscriptionViewController.self) {
                    vc.present(vcSub, animated: true)
                }
            }
            else if message["watch"] == "end"
            {
                Settings.isZensorConnected = false
                Settings.connectedDate = nil
                NotificationCenter.default.post(name: .endSession, object: nil)
            }
            else if message["watch"] == "endSession"
            {
                Settings.isUploadDate = true
            }
            else if message["watch"] == "start"
            {
                Settings.isZensorConnected = true
                Settings.connectedDate = Date ()
                NotificationCenter.default.post(name: .startSession, object: Settings.connectedDate)
            }
            else if let progress = message["progress"] {
            
                NotificationCenter.default.post(name: NSNotification.Name("progress"),
                                                object: progress )
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "watch_progress"))
            }
            
            else if let facebook = message["facebook"] {
                
                AppEvents.logEvent(AppEvents.Name(rawValue: facebook))
            }
        }
        else if(message.first?.key == "sample")
        {
            if let sample = message.first?.value
            {                
                NotificationCenter.default.post(name: .sample,
                                                object: sample)
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "watch_sample"))
            }
        }
    }
}
