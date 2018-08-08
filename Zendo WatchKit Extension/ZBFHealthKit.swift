//
//  ZBFHealthKit.swift
//  Zendo
//
//  Created by Douglas Purdy on 3/23/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import HealthKit

class ZBFHealthKit {
    
    static let healthStore = HKHealthStore()
    
    static let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    static let heartRateSDNNType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
    static let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    static let workoutType = HKObjectType.workoutType()
    
    static let hkShareTypes = Set([heartRateType, mindfulSessionType, workoutType, heartRateSDNNType])
    static let hkReadTypes = hkShareTypes
    
    class func getPermissions()  {
        
        healthStore.requestAuthorization(
            toShare: hkShareTypes,
            read: hkReadTypes,
            completion: { success, error in
                
                if !success && error != nil {
                    print(error.debugDescription);
                }
        })
    }
    
}
