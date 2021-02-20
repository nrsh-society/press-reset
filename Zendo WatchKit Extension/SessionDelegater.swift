//
//  SessionDelegater.swift
//  FinanceWatch Extension
//
//  Created by Anton Pavlov on 24/06/2018.
//  Copyright © 2018 Anton Pavlov. All rights reserved.
//

import UIKit
import WatchConnectivity

class SessionDelegater: NSObject, WCSessionDelegate, SessionCommands {
    
    override init()
    {
        super.init()
        
        if (WCSession.default.activationState == WCSessionActivationState.notActivated)
        {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation did complete")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("watch received app context: ", applicationContext)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        if let message = message as? [String: String] {
            
            if message["phone"] == "end" {
                NotificationCenter.default.post(name: .endSessionFromiPhone, object: nil)
            }
            
        }
    }
    
    
    
}
