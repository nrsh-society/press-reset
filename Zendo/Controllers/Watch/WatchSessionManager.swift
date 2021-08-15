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
            if message["watch"] == "mixpanel"
            {
                if let email = Settings.email,
                let name = Settings.fullName
                {
                    replyHandler(["email": email, "name": name])
                }
                
            }
            else if message["watch"] == "registerNotifications"
            {
                DispatchQueue.main.async
                {
                    UIApplication.shared.registerForRemoteNotifications()
                }

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
                if(Settings.isZensorConnected)
                {
                    
                    NotificationCenter.default.post(name: .endSession, object: nil)
                    NotificationCenter.default.post(name: .reloadActivity, object: nil)
                    NotificationCenter.default.post(name: .reloadOverview, object: nil)
                }
 
                Settings.isZensorConnected = false
                Settings.connectedDate = nil
                Settings.isUploadDate = true
                
            }
            else if message["watch"] == "start"
            {
                if(!Settings.isZensorConnected)
                {
                    Settings.isZensorConnected = true
                    Settings.connectedDate = Date ()
                    
                    NotificationCenter.default.post(name: .startSession, object: Settings.connectedDate)
                }
            }
            else if let progress = message["progress"]
            {
                Settings.isZensorConnected = true
                Settings.connectedDate = Date ()
                
                NotificationCenter.default.post(name: NSNotification.Name("progress"),
                                                object: progress )
                
            }
            
            else if let facebook = message["facebook"] {
                
            }
        }
        else if(message.first?.key == "sample")
        {
            Settings.isZensorConnected = true
            Settings.connectedDate = Date ()
            
            if let sample = message.first?.value
            {                
                NotificationCenter.default.post(name: .sample,
                                                object: sample)
            }
        }
    }
}
