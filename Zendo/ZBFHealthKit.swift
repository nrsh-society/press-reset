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
        
        cell.textLabel?.text = "\(Int(minutes).description)min"
        
        cell.detailTextLabel?.text = ZBFHealthKit.format(date: workout.endDate)
        
        cell.imageView?.contentMode = .scaleAspectFit
        
        cell.imageView?.image = getImage(workout: workout)
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: workout.endDate, options: .strictEndDate)
        
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
                                                    
                                                    if let layers = cell.imageView?.layer.sublayers {
                                                        
                                                        for layer in layers {
                                                    
                                                            if layer.name == "hrv" {
                                                            
                                                                layer.removeFromSuperlayer()
                                                            
                                                            }
                                                        }
                                                    }
                                                    
                                                    let text = CATextLayer()
                                                    text.name = "hrv"
                                                    
                                                    text.string = Int(value).description
                                                    text.foregroundColor = UIColor.white.cgColor
                                                    text.font = UIFont(name: "Menlo-Bold", size: 25.0)
                                                    text.fontSize = 25.0
                                                    //text.alignmentMode = kCAAlignmentCenter
                                                    text.backgroundColor = UIColor.clear.cgColor
                                                    text.frame = CGRect(x: (cell.imageView?.frame.minX)!, y: (cell.imageView?.frame.minY)! + 17, width: (cell.imageView?.frame.width)!, height: (cell.imageView?.frame.height)!)
                                                    
                                                    cell.imageView?.layer.addSublayer(text)
                                                    
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    class func getImage(workout: HKWorkout) -> UIImage {
        
        let minutes = Int(workout.duration / 60)
        
        //#todo: this should be in options
        let goalMintues = 20
        
        let delta = minutes - goalMintues
        
        let image : UIImage = UIImage(named: "shobogenzo")!
        
        var size = CGSize(width: 75 , height: 75)
        
        if (delta < 0) {
            size = CGSize(width: size.width - CGFloat(delta) ,
                          height: size.height - CGFloat(delta))
        }
        
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
