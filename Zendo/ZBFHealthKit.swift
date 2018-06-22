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
    
    class func overlayHRV(workout : HKWorkout, imageView : UIImageView ) {
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictEndDate)
        
        let options : HKStatisticsOptions  = HKStatisticsOptions.discreteAverage
    
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) {
                                            query, result, error in
    
                                            if(error != nil) {
                                                print(error.debugDescription);
                                            }
    
                                            if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
    
                                                DispatchQueue.main.async() {
                                                    
                                                    let text = CATextLayer()
                                                    text.string = String(format: "%.1f", value)
                                                    text.foregroundColor = UIColor.white.cgColor
                                                    text.font = UIFont(name: "Menlo-Bold", size: 33.0)
                                                    text.fontSize = 33.0
                                                    text.alignmentMode = kCAAlignmentCenter
                                                    text.backgroundColor = UIColor.clear.cgColor
                                                    text.frame = CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height)
                                                    
                                                    imageView.layer.addSublayer(text)
                                                
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
    class func populateCell(workout : HKWorkout, cell:UITableViewCell)  {
        
        let minutes = (workout.duration / 60).rounded()
        
        cell.textLabel?.text = "\(Int(minutes).description) minutes"
        
        cell.detailTextLabel?.text = ZBFHealthKit.format(date: workout.endDate)
        
        cell.imageView?.contentMode = .scaleAspectFit
        
        cell.imageView?.image = getImage(workout: workout)
        
        overlayHRV(workout: workout, imageView: cell.imageView!)
        
        UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            
            let scale = CGAffineTransform(scaleX: 1 + CGFloat(minutes / 10), y: 1 + CGFloat(minutes / 10))
            
            cell.imageView?.transform = scale
            
        }, completion: nil)
    }
    
    class func getImage(workout: HKWorkout) -> UIImage {
        
        let minutes = Int((workout.duration / 60))
        
        let image : UIImage = UIImage(named: "shobogenzo")!
        
        let size = CGSize(width: 55 + minutes, height: 55 + minutes)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        image.draw(in: rect)
        
        let retval : UIImage! = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    
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
