//
//  ZendoTableViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 30/07/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import HealthKit

class FirstSessionTableViewCell: UITableViewCell {
    @IBOutlet weak var bottomLabel: UILabel! {
        didSet {
            bottomLabel.font = UIFont.zendo(font: .antennaRegular, size: bottomLabel.font.pointSize - (UIDevice.small ? 2 : 0))
            let attributedString = NSMutableAttributedString(string: bottomLabel.text ?? "")
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.43
            
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attributedString.length))
        }
    }
    @IBOutlet weak var imageHeight: NSLayoutConstraint! {
        didSet {
            if UIDevice.small {
                imageHeight.constant = 255.0
            }
        }
    }
}

class HeaderZendoTableViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
}

class ZendoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var pulseLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var workout: HKSample! {
        didSet {
            durationLabel?.text = workout.duration.stringZendoTimeWatch
            timeLabel.text = workout.endDate.toZendoEndString.lowercased()
            
            let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
            
            let hkPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            
            let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                            quantitySamplePredicate: hkPredicate,
                                            options: .discreteAverage) { query, result, error in
                                                
                                                if error != nil {
                                                    print(error.debugDescription)
                                                }
                                                
                
                if let result = result
                {
                                                if let value = result.averageQuantity()?.doubleValue(for: HKUnit(from: "ms"))
                                                {
                                                    DispatchQueue.main.async()
                                                    {
                                                        if (value > 0)
                                                        {
                                                            self.pulseLabel.text = Int(value.rounded()).description + "ms"
                                                        }
                                                        else
                                                        {
                                                            self.pulseLabel.text = " ----- "
                                                        }
                                                    }
                                                }
                                                } else {
                                                    DispatchQueue.main.async() {
                                                        self.pulseLabel.text = " ----- "
                                                    }
                                                }
            }
            
            ZBFHealthKit.healthStore.execute(hkQuery)
        }
    }
    
}
