//
//  ZendoTableViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 30/07/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import HealthKit

class HeaderZendoTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
}

class ZendoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var pulseLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var workout: HKWorkout! {
        didSet {
            durationLabel?.text = workout.duration.stringZendoTime
            timeLabel.text = workout.endDate.toZendoEndString.lowercased()
            
            let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
            
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)
            
            let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: workout.endDate, options: .strictEndDate)
            
            let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                            quantitySamplePredicate: hkPredicate,
                                            options: .discreteAverage) { query, result, error in
                                                
                                                if error != nil {
                                                    print(error.debugDescription)
                                                }
                                                
                                                if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                    DispatchQueue.main.async() {
                                                        self.pulseLabel.text = Int(value).description + "ms"
                                                    }
                                                } else {
                                                    DispatchQueue.main.async() {
                                                        self.pulseLabel.text = "0ms"
                                                    }
                                                }
            }
            
            ZBFHealthKit.healthStore.execute(hkQuery)
        }
    }
    
}
