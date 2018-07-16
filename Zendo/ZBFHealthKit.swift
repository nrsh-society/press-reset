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
    
    static let hkShareTypes = Set([heartRateType, mindfulSessionType, workoutType, heartRateSDNNType, restingBPMType])
    
    static let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    
     static let restingBPMType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!
    
    static let heartRateSDNNType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
    
    static let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    
    static let workoutType = HKObjectType.workoutType()
    
    static let workoutPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody)
    
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
        
        cell.textLabel?.text = "\(Int(minutes).description) min"
        
        cell.detailTextLabel?.text = ZBFHealthKit.format(workout.endDate)
        
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
                                                    
                                                    let size = (cell.imageView?.image?.size)!
                                                    
                                                    cell.imageView?.image =  generateImageWithText(size: size, text: Int(value).description, fontSize: 33.0)
                                                 
                                                    UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                                                        
                                                        let scale = CGAffineTransform(scaleX: 1 - CGFloat(value/100), y: 1 - CGFloat(value/100))
                                                        
                                                        cell.imageView?.transform = scale
                                                        
                                                        cell.imageView?.transform = CGAffineTransform.identity
                                                        
                                                    }, completion: nil )
                                                    
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    class func getImage(workout: HKWorkout) -> UIImage {
        
        let image : UIImage = UIImage(named: "shobogenzo")!
        
        let size = CGSize(width: 100 , height: 100)
        
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

    class func format(_ date: Date) -> String {
    
        let dateFormatter = DateFormatter();
        
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY-MM-dd")
    
        let localDate = dateFormatter.string(from: date)
    
        dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
        
        let localTime = dateFormatter.string(from: date)
        
        return localDate + " " + localTime
    }
    
    class func generateImageWithText(size: CGSize, text: String, fontSize: CGFloat ) -> UIImage
    {
        let image = UIImage(named: "shobogenzo")!
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = rect
        imageView.backgroundColor = UIColor.clear
        
        let label = UILabel(frame: rect)
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: fontSize)
        
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0);
        
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let imageWithText = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        
        return imageWithText!
    }
    
    class func deleteWorkout(workout: HKWorkout)
    {
        getSamples(workout: workout)
        {
            samples in
            
            var objects : [HKSample] = samples.map { $0 }
            
            objects.append(workout)
            
            healthStore.delete(objects)
            {
                (bool, error) in
                                    
                    if(!bool)
                    {
                        print(error!)
                    }
            }
        }
        
    }
    
    typealias GetSamplesHandler = ([HKSample]) -> Void
    
    class func getSamples(workout: HKWorkout, handler: @escaping GetSamplesHandler )
    {
        
        let hkPredicate = HKQuery.predicateForObjects(from: workout as HKWorkout)
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler:
        {
            query, results, error in
        
                if(error != nil )
                {
                    print(error!)
                }
                else
                {
                    handler(results!)
                }
        })
    
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    typealias GetPermissionsHandler = (_ success: Bool, _ error: Error?) -> Void
    
    class func requestHealthAuth(handler: @escaping GetPermissionsHandler)  {
        
        healthStore.handleAuthorizationForExtension
        {
            (success, error) in
            
            healthStore.requestAuthorization(
                toShare: hkShareTypes,
                read: hkReadTypes,
                completion: handler)
        }
    }
    
    //#todo(debt): need to be consistent in the return of the handler functions?
    typealias SamplesHandler = (_ samples: [Double : Double]?, _ error: Error? ) -> Void
    
    class func getMindfulMinutes(interval: Calendar.Component, value: Int, handler:  @escaping SamplesHandler)
    {
        let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let hkCategoryPredicate = HKQuery.predicateForCategorySamples(with: .equalTo, value: 0)
        
        let end = Date()
        
        let prior = Calendar.current.date(byAdding: interval, value: -(value), to: end)!
        
        let hkDatePredicate = HKQuery.predicateForSamples(withStart: prior, end: end, options: .strictStartDate)
        
        let hkPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [hkCategoryPredicate, hkDatePredicate])
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: true)
        
        let hkSampleQuery = HKSampleQuery(sampleType: hkType, predicate: hkPredicate, limit: 0,
                                          sortDescriptors: [sortDescriptor])
        {
            (query, samples, error) in
            
            var entries : [Double : Double] = [:]
            
            if let samples = samples
            {
                samples.forEach(
                    {
                        (sample) in
                        
                        let startDate = sample.startDate
                        
                        let calendar = Calendar.current
                        
                        let components = calendar.dateComponents(in: calendar.timeZone, from: startDate)
                        
                        let endDate = sample.endDate
                        
                        let delta = DateInterval(start: startDate, end: endDate)
                        
                        var date = Date()
                        
                        switch interval
                        {
                        case .hour:
                            date = Calendar.current.date(bySettingHour: components.hour!, minute: 0, second: 0, of: startDate)!
                            break
                            
                        case .day:
                            date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: startDate)!
                            break
                            
                        case .month:
                            let components = Calendar.current.dateComponents([.year, .month], from: startDate)
                            date = Calendar.current.date(from: components)!
                            
                            break
                            
                        case .year:
                            let components = Calendar.current.dateComponents([.year], from: startDate)
                            date = Calendar.current.date(from: components)!
                            break
                            
                        default:
                            date = Calendar.current.date(bySettingHour: components.hour!, minute: 0, second: 0, of: startDate)!
                            break
                        }
                        
                        let key = date.timeIntervalSince1970
                        
                        if let existingValue = entries[key]
                        {
                            entries[key] = existingValue + delta.duration
                        }
                        else
                        {
                            entries[key] = delta.duration
                        }
                })
            }
                
            handler(entries, error)
        }
        
        healthStore.execute(hkSampleQuery)
    }
    
    class func getHRVSamples(interval: Calendar.Component, value: Int, handler: @escaping SamplesHandler)
    {
        var entries : [Double : Double] = [:]
        
        let end = Date()
        
        var components = DateComponents()
        
        switch interval
        {
            case .hour:
                components.hour = 4
                break
            
            case .day:
                components.day = 1
                break
            
            case .month:
                components.day = 7
                break
            
            case .year:
                components.month = 1
                break
            
            default:
                components.day = 1
                break
        }
        
        let prior = Calendar.current.date(byAdding: interval, value: -(value), to: end)!
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
    
        let query = HKStatisticsCollectionQuery(quantityType: hkType,
                                                quantitySamplePredicate: nil,
                                                options: HKStatisticsOptions.discreteAverage,
                                                anchorDate: prior,
                                                intervalComponents: components)
        
        query.initialResultsHandler = {
            
            query, results, error in
            
            if let statsCollection = results
            {
                statsCollection.enumerateStatistics(from: prior, to: end )
                {
                    statistics, stop in
                    
                    var avgValue = 0.0
                    
                    if let avgQ = statistics.averageQuantity()
                    {
                        avgValue = avgQ.doubleValue(for: HKUnit(from: "ms"))
                    }
                    
                    let key = statistics.startDate.timeIntervalSince1970
                    
                    entries[key] = avgValue
                    
                }
                
                handler(entries, nil)
            }
            else
            {
                handler(nil, error)
            }
        }
        
        healthStore.execute(query)
    }
        
    class func getBPMSamples(interval: Calendar.Component, value: Int, handler: @escaping SamplesHandler)
    {
        var entries : [Double : Double] = [:]
        
        let end = Date()
        
        var components = DateComponents()
        
        switch interval
        {
        case .hour:
            components.hour = 4
            break
            
        case .day:
            components.day = 1
            break
            
        case .month:
            components.day = 7
            break
            
        case .year:
            components.month = 1
            break
            
        default:
            components.day = 1
            break
        }
        
        let prior = Calendar.current.date(byAdding: interval, value: -(value), to: end)!
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!
        
        let query = HKStatisticsCollectionQuery(quantityType: hkType,
                                                quantitySamplePredicate: nil,
                                                options: HKStatisticsOptions.discreteAverage,
                                                anchorDate: prior,
                                                intervalComponents: components)
        
        query.initialResultsHandler = {
            
            query, results, error in
            
            
            
            if let statsCollection = results
            {
                statsCollection.enumerateStatistics(from: prior, to: end )
                {
                    statistics, stop in
                    
                    var avgValue = 0.0
                    
                    if let avgQ = statistics.averageQuantity()
                    {
                        avgValue = avgQ.doubleValue(for: HKUnit(from: "count/s"))
                    }
                
                    let key = statistics.startDate.timeIntervalSince1970
                    
                    entries[key] = (avgValue * 60.0)
                    
                }
                
                handler(entries, nil)
            }
            else
            {
                handler(nil, error)
            }
        }
    
        healthStore.execute(query)
    }
}
