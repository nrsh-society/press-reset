//
//  ZendoTableViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 30/07/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import HealthKit

class ZendoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var pulseLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var workout: HKWorkout! {
        didSet {
            print(workout.duration)
            durationLabel?.text = workout.duration.stringZendoTime
            timeLabel.text = workout.endDate.toZendoEndString.lowercased()
            
            let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
            
         //   let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)
            
            let hkPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictEndDate)
            
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
    
    func getDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        
        if minutes > 1 {
            return minutes.description + "mins"
        } else if minutes == 1 {
            return minutes.description + "min"
        }
        return "eeee"
    }
    
    
    //    override func awakeFromNib() {
    //        super.awakeFromNib()
    //        // Initialization code
    //    }
    //
    //    override func setSelected(_ selected: Bool, animated: Bool) {
    //        super.setSelected(selected, animated: animated)
    //
    //        // Configure the view for the selected state
    //    }
    
    
    //    class func populateCell(workout: HKWorkout, cell: UITableViewCell) {
    //
    //        let minutes = (workout.duration / 60).rounded()
    //
    //        cell.textLabel?.text = "\(Int(minutes).description) min"
    //
    //        cell.detailTextLabel?.text = ZBFHealthKit.format(workout.endDate)
    //
    //        cell.imageView?.contentMode = .scaleAspectFit
    //
    //        cell.imageView?.image = getImage(workout: workout)
    
}
