//
//  ZendoKit.swift
//  ZendoMsg
//
//  Created by Douglas Purdy on 7/6/19.
//  Copyright © 2019 zenbf. All rights reserved.
//

import Foundation
import HealthKit


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

