//
//  SubscribeInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 15/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import WatchKit

class SubscribeInterfaceController: WKInterfaceController {
    
    private lazy var sessionDelegater: SessionDelegater = {
        return SessionDelegater()
    }()

    @IBAction func subscribeAction() {
        sessionDelegater.sendMessage(["watch": "present"], replyHandler: { replyHandler in
            
        }, errorHandler: { error in
            
        })
        dismiss()
    }
    
    @IBAction func cancelAction() {
//        dissmis()
        Session.current = Session()

        Session.current?.start()

        WKInterfaceDevice.current().play(WKHapticType.start)

        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: Session.current as AnyObject)])
        
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        invalidateUserActivity()
    }
    
}
