//
//  WatchSessionManager.swift
//  Zendo
//
//  Created by Anton Pavlov on 16/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchConnectivity


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
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        
        if let message = message as? [String: String] {
            
            if message["watch"] == "reload" {
                
                NotificationCenter.default.post(name: .reloadActivity, object: nil)
                NotificationCenter.default.post(name: .reloadOverview, object: nil)
                
            } else if message["watch"] == "mixpanel" {
                
                if let email = Settings.email, let name = Settings.fullName {
                    replyHandler(["email": email, "name": name])
                }
            }
        }
        
    }
    
}

