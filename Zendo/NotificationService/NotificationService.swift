//
//  NotificationService.swift
//  NotificationService
//
//  Created by Douglas Purdy on 1/9/19.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UserNotifications
import HealthKit

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    /*
         run when the below is sent in a remote notification
     
         {
            "aps": { "mutable-content": 1 }
         }
     
     */
 
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
 
 /*
        
        if let bestAttemptContent = bestAttemptContent
        {
            var now = Date()
            var yesterday = now.addingTimeInterval(-86400)
            var lastNow = now.addingTimeInterval(-604800)
            var lastYesterday = yesterday.addingTimeInterval(-604800)
            
            self.getHRVAverage(start: yesterday, end: now)
            {
                (samples, error) in
                
                var todayHRV = Int(samples![0]!)
                
                self.getHRVAverage(start: lastYesterday, end: lastNow)
                {
                    (samples, error) in
                    
                    var lastHRV = Int(samples![0]!)
                    
                    var wow_hrv_delta = todayHRV - lastHRV
                    
                    bestAttemptContent.title = "Weekly HRV Summary"
                    bestAttemptContent.body = "Your HRV is \(wow_hrv_delta)ms this week from \(lastHRV)ms last week."
                    
                    contentHandler(bestAttemptContent)
                }
                
            }
        }
 
 */
        
    }
    
    override func serviceExtensionTimeWillExpire() {

        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    
    /*
     #todo: refactor ZBFHealthKit to make it useable in different processes/projects.
    */
 
    
    typealias SamplesHandler = (_ samples: [Double: Double]?, _ error: Error? ) -> Void
    
    func getHRVAverage(start: Date, end: Date, handler: @escaping SamplesHandler) {
        
        let hkType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let options: HKStatisticsOptions = [HKStatisticsOptions.discreteAverage, HKStatisticsOptions.discreteMax, HKStatisticsOptions.discreteMin]
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) { query, result, error in
                                            
                                            if let result = result {
                                                if let value = result.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                    let value = [0.0 : value]
                                                    handler(value, nil)
                                                } else {
                                                    handler(nil, nil)
                                                }
                                            } else {
                                                handler(nil, error)
                                            }
        }
        
        HKHealthStore().execute(hkQuery)
    }
    

}
