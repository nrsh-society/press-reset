//
//  SubscribeInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 15/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import WatchKit

class SubscribeInterfaceController: WKInterfaceController {

    @IBAction func subscribeAction() {
//        if #available(watchOSApplicationExtension 5.0, *) {
//            let userActivity = NSUserActivity(activityType: SettingsWatch.sharedUserActivityType)
////            userActivity.userInfo = [SettingsWatch.sharedIdentifierKey: "openApp"]
//            userActivity.delegate = self
//            userActivity.isEligibleForPublicIndexing = true
////            userActivity.isEligibleForHandoff = true
//            update(userActivity)
//            userActivity.becomeCurrent()
//
//        } else {
//            updateUserActivity(SettingsWatch.sharedUserActivityType, userInfo: [SettingsWatch.sharedIdentifierKey: "openApp"], webpageURL: nil)
//        }
        
    }
    
    
    @IBAction func cancelAction() {
        
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

extension SubscribeInterfaceController: NSUserActivityDelegate {
    
    func userActivityWillSave(_ userActivity: NSUserActivity) {
        if #available(watchOSApplicationExtension 5.0, *) {
            print(userActivity.activityType)
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    /* The user activity was continued on another device.
     */
    func userActivityWasContinued(_ userActivity: NSUserActivity) {
        if #available(watchOSApplicationExtension 5.0, *) {
            print(userActivity.persistentIdentifier)
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    /* If supportsContinuationStreams is set to YES the continuing side can request streams back to this user activity. This delegate callback will be received with the incoming streams from the other side. The streams will be in an unopened state. The streams should be opened immediately to start receiving requests from the continuing side.
     */
    func userActivity(_ userActivity: NSUserActivity, didReceive inputStream: InputStream, outputStream: OutputStream) {
        if #available(watchOSApplicationExtension 5.0, *) {
            print(userActivity.persistentIdentifier)
        } else {
            // Fallback on earlier versions
        }
    }
}
