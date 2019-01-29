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
        
        ZBFHealthKit.healthStore.execute(hkQuery)
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
        
        ZBFHealthKit.healthStore.execute(hkSampleQuery)
    }
    
}
