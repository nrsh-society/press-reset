//
//  ZazenController.swift
//  Zendo
//
//  Created by Douglas Purdy on 3/27/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import HealthKit
import Foundation
import Charts

class ZazenController : UIViewController, IAxisValueFormatter {
    
    public var workout : HKWorkout!
    public var samples: [[String:Any]]!
    
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var hrvLabel: UILabel!
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var programImage: UIImageView!
    
    override func viewDidLoad() {
        
        let hkPredicate = HKQuery.predicateForObjects(from: workout as HKWorkout)
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: true)
        
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query, results, error in
 
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.async() {
                    
                    self.samples = results!.map({ (sample) -> [String:Any] in
                        return sample.metadata!
                    });
                    
                    self.populateChart()
                    self.populateSummary()
                    
                };
            }
            
        });
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    @IBAction func export(_ sender: Any)
    {
        let vc : UIActivityViewController = export(samples: self.samples)
        
        present(vc, animated: true, completion: nil)
    }
    
    
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true) {}
    }
    
    func populateSummary() {
    
        var hkType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        var hkPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictEndDate)
        
        //#todo: this seems wrong
        let options : HKStatisticsOptions = HKStatisticsOptions(rawValue: HKStatisticsOptions.RawValue(UInt8(HKStatisticsOptions.discreteMin.rawValue) | UInt8(HKStatisticsOptions.discreteMax.rawValue)))
        
        var hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) { query, result, error in
                                            
                                            if(error != nil) {
                                                print(error.debugDescription);
                                            }
                                            
                                            if let value = result!.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                
                                                 DispatchQueue.main.async() {
                                                
                                                    self.minLabel.text = String(value * 60.0)
                                                
                                                }
                                            }
                                            
                                            if let value = result!.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                
                                                 DispatchQueue.main.async() {
                                                    
                                                    self.maxLabel.text = String(value * 60.0)
                                                }
                                            }
                              
        }
        
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
        hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)
        
        hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: workout.endDate, options: .strictEndDate)
        
        hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: .discreteAverage) { query, result, error in
                                            
                                            if(error != nil) {
                                                print(error.debugDescription);
                                            }
                                            
                                            if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                
                                                 DispatchQueue.main.async() {
                                                
                                                    self.hrvLabel.text = String(format: "%.1f", value)
                                                    
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    func getChartDataSet(key: String, color: UIColor) -> LineChartDataSet {
        
        var entries = [ChartDataEntry]()
        
        for(index, sample) in samples.enumerated() {
            
            if let value = sample[key] as? String {
                
                let y = Double(value)!
                
                entries.append(ChartDataEntry(x: Double(index), y: y ))
            }
            
        }
        
        let retval = LineChartDataSet(values: entries, label: key)
        
        retval.setColor(color)
        
        retval.drawCirclesEnabled = false
        
        return retval
        
    }
    
    func populateChart() {
        
        var rate = getChartDataSet(key: "heart", color: UIColor.red )
       
        //#todo: support v.002 schema
        if rate.entryCount == 0 {
            
            rate = getChartDataSet(key: "heart", color: UIColor.red )
        }
        
        rate.lineWidth = 3.0
        
        let movement = getChartDataSet(key: "motion", color: UIColor.green)
        
        movement.lineWidth = 2.5
        
        let data = LineChartData(dataSets: [rate, movement])
        
        chartView.xAxis.valueFormatter = self
        
        if(rate.entryCount > 0) {  chartView.data = data }
       
        chartView.autoScaleMinMaxEnabled = true
        
        chartView.chartDescription?.enabled = false
        
        chartView.noDataText = "No samples"
        
        if(rate.entryCount > 0) {  chartView.data = data }
        
        chartView.animate(xAxisDuration: 3)
        
    }
    
    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        
        let label = (value / 60)
        
        return String(format: "%.2f", label)
    }
    
    func export(samples: [[String:Any]]) -> UIActivityViewController {
        
        let fileName = "zazen.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "now, program, rate, sdnn, motion\n"
        
        for sample in samples {
            
            let line : String =
                "\(sample["now"]!),"  +
                    "\(sample["heart"]!)," +
                    "\(sample["sdnn"]!)," +
                    "\(sample["motion"]!)"
            
            csvText += line  + "\n"
        }
        
        do {
            
            try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            
        } catch {
            
            print("Failed to create file")
            print("\(error)")
        }
        
        let vc = UIActivityViewController(activityItems: [path as Any], applicationActivities: [])
        
        vc.excludedActivityTypes = [
            UIActivityType.assignToContact,
            UIActivityType.saveToCameraRoll,
            UIActivityType.postToFlickr,
            UIActivityType.postToVimeo,
            UIActivityType.postToTencentWeibo,
            UIActivityType.postToTwitter,
            UIActivityType.postToFacebook,
            UIActivityType.openInIBooks
        ]
        
        return vc
        
    }


}
