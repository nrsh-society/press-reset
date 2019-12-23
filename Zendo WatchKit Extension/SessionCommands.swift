//
//  SessionCommands.swift
//  FinanceWatch Extension
//
//  Created by Anton Pavlov on 24/06/2018.
//  Copyright © 2018 Anton Pavlov. All rights reserved.
//

import UIKit
import WatchConnectivity

protocol SessionCommands {
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?)
}


extension SessionCommands {
    
    func sendMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {

        guard WCSession.default.activationState == .activated else {
            return handleSessionUnactivated()
        }

        WCSession.default.sendMessage(message, replyHandler: { replyMessage in
            replyHandler?(replyMessage)
        }, errorHandler: { error in
            errorHandler?(error)
            print(error.localizedDescription)
        })
    }
    
    private func handleSessionUnactivated() {
       print("handleSessionUnactivated")
    }
}
