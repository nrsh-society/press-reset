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
    typealias SamplesHandlerDouble = (_ samples: Double?, _ error: Error? ) -> Void
    
    static let healthStore = HKHealthStore()
    
    static let hkReadTypes = hkShareTypes
    static let hkShareTypes = getPermissionTypes()

    class func getPermissionTypes() -> Set<HKSampleType>
    {
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!

        return [heartRateType, hrvType, mindfulSessionType, HKObjectType.workoutType()]
    
    }
    
    typealias PermissionsHandler = ( _ success: Bool, _ error : Error?) -> Void
   
    class func getPermissions(handler: @escaping PermissionsHandler)
    {
        healthStore.requestAuthorization(
            toShare: hkShareTypes,
            read: hkReadTypes,
            completion:
            {
                    success, error in
                
                    handler (success, error)
            })
    }
    
    typealias HRVSampleHandler = ( _ double: Double, _ error : Error?) -> Void
    
    class func getHRVAverage(_ handler: @escaping HRVSampleHandler)
    {
    
        let hkType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let today = Calendar.autoupdatingCurrent.startOfDay(for: Date())

        let hkPredicate = HKQuery.predicateForSamples(withStart: today, end: Date(), options: .strictStartDate)
        
        let options = HKStatisticsOptions.discreteAverage
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options)
            {
                query, result, error in
                                            
                    if error != nil
                    {
                        handler(0.0, error)
                    }
                    else
                    {
                        if let result = result
                        {
                            if let value = result.averageQuantity()?.doubleValue(for: HKUnit(from: "ms"))
                            {
                                handler(value, nil)
                            }
                        }
                    }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    class func getHRVAverage(_ workout: HKSample, handler: @escaping SamplesHandler) {
        
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
        
        healthStore.execute(hkQuery)
    }
    
    class func getHRVAverage(start: Date, end: Date, handler: @escaping SamplesHandler) {
        
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
        
        healthStore.execute(hkQuery)
    }
    
    class func getMindfulMinutes(handler: @escaping SamplesHandlerDouble) {
        
        let start = Date().startOfDay
        let end = Date().endOfDay
        
        let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let hkDatePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        var sum = 0.0
        
        let hkSampleQuery = HKSampleQuery(sampleType: hkType,
                                          predicate: hkDatePredicate,
                                          limit: HKObjectQueryNoLimit,
                                          sortDescriptors: [sortDescriptor]) { query, samples, error in
                                            
                                            if let samples = samples{
                                                
                                                samples.forEach( { sample in
                                                    
                                                    let delta = DateInterval(start: sample.startDate, end: sample.endDate)
                                                    
                                                    sum += delta.duration
                                                })
                                                
                                                handler(sum, error)
                                                
                                            } else {
                                                handler(sum, error)
                                            }
                                            
        }
        
        healthStore.execute(hkSampleQuery)
    }
    
}


