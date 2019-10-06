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
                
                FBSDKAppEvents.logEvent("watch_identity")
            }
            else if message["watch"] == "registerNotifications"
            {
                DispatchQueue.main.async
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                FBSDKAppEvents.logEvent("watch_notification")
            }
            else if message["watch"] == "subscribe"
            {
                Settings.checkSubscriptionAvailability { bool, trial in
                    replyHandler(["isSubscribe": bool, "isTrial": trial])
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

                Settings.isSensorConnected = false
                Settings.connectedDate = nil
                NotificationCenter.default.post(name: .endSession, object: nil)
            }
            else if message["watch"] == "start"
            {
                Settings.isSensorConnected = true
                Settings.connectedDate = Date ()
                NotificationCenter.default.post(name: .startSession, object: Settings.connectedDate)
            }
            else if let progress = message["progress"] {
            
                NotificationCenter.default.post(name: NSNotification.Name("progress"),
                                                object: progress )
                
                FBSDKAppEvents.logEvent("watch_progress")
            }
            
            else if let facebook = message["facebook"] {
                
                FBSDKAppEvents.logEvent(facebook)
            }
        }
        else if(message.first?.key == "sample")
        {
            if let sample = message.first?.value
            {                
                NotificationCenter.default.post(name: NSNotification.Name("sample"),
                                                object: sample )
                
                FBSDKAppEvents.logEvent("watch_sample")
            }
        }
    }
}
