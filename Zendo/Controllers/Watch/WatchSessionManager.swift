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
        else if(message.first?.key == "facebook")
        {
            if let event = message.first?.value
            {
                FBSDKAppEvents.logEvent(event as? String)
            }
        }
    }
}
