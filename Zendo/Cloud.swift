//
//  Cloud.swift
//  zendoArena
//
//  Created by Douglas Purdy on 2/12/19.
//  Copyright © 2019 Zendo Tools. All rights reserved.
//

import Foundation
import Mixpanel
import AppTrackingTransparency
import Parse

class Cloud
{
    static var enabled = false

    static func enable(_ application: UIApplication, _ options : [UIApplicationLaunchOptionsKey : Any]?)
    {
        if #available(iOS 14, *) {
            
            ATTrackingManager.requestTrackingAuthorization { status in
                
                if (status == .authorized)
                {
                    //ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: options)
                }
            }
        }
        
        if(!Parse.isLocalDatastoreEnabled)
        {
            Parse.enableLocalDatastore()
        }
        
        let parseConfig = ParseClientConfiguration
        {
            $0.applicationId = "APPLICATION_ID"
            $0.server = "http://code.zendo.tools:1337/parse"
            $0.clientKey = "CLIENT_KEY"
        }
        
        Parse.initialize(with: parseConfig)
       
        //FirebaseApp.configure()
    
        Mixpanel.initialize(token: "73167d0429d8da0c05c6707e832cbb46", trackAutomaticEvents: true)
        
        //BuddyBuildSDK.setup()
        
        CommunityDataLoader.load()
        
        self.enabled = true
    }
}
