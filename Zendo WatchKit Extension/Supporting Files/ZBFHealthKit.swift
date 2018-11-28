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
    
    typealias SamplesHandler = (_ samples: [Double: Double]?, _ error: Error? ) -> Void
    
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
    
    class func getHRVAverage(_ workout: HKWorkout, handler: @escaping SamplesHandler) {
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        //let yesterday = Calendar.autoupdatingCurrent.startOfDay(for: workout.endDate)
        
        //let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        
        let options: HKStatisticsOptions  = [.discreteAverage, .discreteMax, .discreteMin]
        
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
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
}
