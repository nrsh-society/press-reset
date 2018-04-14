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
        
        let minutes = (workout.duration / 60).rounded()
        
        cell.textLabel?.text = Int(minutes).description;
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 33.0);
        
        cell.detailTextLabel?.text = ZBFHealthKit.format(date: workout.endDate)
        
        UIView.animate(withDuration: 1) {
            
            cell.imageView?.transform = CGAffineTransform(scaleX: CGFloat(minutes), y: CGFloat(minutes))
            
            cell.imageView!.image = getImage(duration: workout.duration)
        
        }
    }
    
    class func getImage(duration: TimeInterval) -> UIImage {
        
         var retval : UIImage? = nil
        
        let minutes = Int((duration / 60))
        
        switch (minutes) {
        
            case 0...9:
                retval = UIImage(named: "shobogenzo60")
                break
            
            case 10...19:
                retval = UIImage(named: "shobogenzo70")
                break

            case 20...29:
                retval = UIImage(named: "shobogenzo80")
                break
            
            case 30...39:
                retval = UIImage(named: "shobogenzo90")
                break
            
            case 40...:
                retval = UIImage(named: "shobogenzo100")
                break
            
            default:
                retval = UIImage(named: "shobogenzo50")
                break
            
        }
        
        return retval!
        
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
