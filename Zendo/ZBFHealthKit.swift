//
//  ZBFHealthKit.swift
//  Zendo
//
//  Created by Douglas Purdy on 3/23/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import HealthKit
import Foundation

class ZBFHealthKit {
    
    static let healthStore = HKHealthStore()
    
    static let hkReadTypes = hkShareTypes
    static let hkShareTypes = Set([heartRateType, mindfulSessionType, workoutType, heartRateSDNNType])
    
    static let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    static let heartRateSDNNType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
    static let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    static let workoutType = HKObjectType.workoutType()
    
    
    class func getPermissions()  {
        
        healthStore.handleAuthorizationForExtension { (success, error) in
            
            healthStore.requestAuthorization(
                toShare: hkShareTypes,
                read: hkReadTypes,
                completion: { (success, error) in
                    
                    if(!success && error != nil) {
                        print(error.debugDescription);
                    }
            })
        }
    }
    
    class func populateCell(workout : HKWorkout, cell:UITableViewCell)  {
        
        cell.textLabel?.text = Int((workout.duration / 60).rounded()).description;
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 33.0);
        
        cell.detailTextLabel?.text = ZBFHealthKit.format(date: workout.endDate)
        
    }
    
    class func getSamples(workout:HKWorkout) -> [HKCategorySample] {
        
        let samples = [HKCategorySample]();
        
        let hkPredicate = HKQuery.predicateForObjects(from: workout)
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: {query,results,error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.sync() {
                    
                };
            }
            
        });
        
        healthStore.execute(hkQuery)
        
        return samples
        
    }
    
    
    class func format(date:Date) -> String {
    
        let dateFormatter = DateFormatter();
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY-MM-dd")
    
        let localDate = dateFormatter.string(from: date)
    
        dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
        
        let localTime = dateFormatter.string(from: date)
        
        return localDate + " " + localTime
    }
        
}
