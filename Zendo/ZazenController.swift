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
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: workout.endDate, options: .strictEndDate)
        
        hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: .discreteAverage) { query, result, error in
                                            
                                            if(error != nil) {
                                                print(error.debugDescription);
                                            }
                                            
                                            if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                
                                                 DispatchQueue.main.async() {
                                                
                                                    self.hrvLabel.text = String(value * 1.0)
                                                    
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    func populateChart() {
        
        
            var rate : [ChartDataEntry] = [ChartDataEntry]()
            
            for(index, sample) in samples.enumerated() {
                
                let value = sample["heart.rate"] as! String;
                
                let y = Double(value)!
                
                rate.append(ChartDataEntry(x: Double(index), y: y ))
                
            }
            
            /*
             var ssdn : [ChartDataEntry] = [ChartDataEntry]()
             
             for(index, sample) in samples.enumerated() {
             
             let value = sample["heart.sdnn"] as! String
             
             let y = Double(value)!
             
             ssdn.append(ChartDataEntry(x: Double(index), y: y ))
             
             }
             */
            
            var yaw : [ChartDataEntry] = [ChartDataEntry]()
            
            for(index, sample) in samples.enumerated() {
                
                let y = Double(sample["attitude.yaw"] as! String)!
                
                yaw.append(ChartDataEntry(x: Double(index), y: y ))
                
            }
            
            var pitch : [ChartDataEntry] = [ChartDataEntry]()
            
            for(index, sample) in samples.enumerated() {
                
                let y = Double(sample["attitude.pitch"] as! String)!
                
                pitch.append(ChartDataEntry(x: Double(index), y: y ))
                
            }
            
            var roll : [ChartDataEntry] = [ChartDataEntry]()
            
            for(index, sample) in samples.enumerated() {
                
                let y = Double((sample["attitude.roll"] as! String))!
                
                roll.append(ChartDataEntry(x: Double(index), y: y ))
                
            }
            
            let set1: LineChartDataSet = LineChartDataSet(values: rate, label: "heart.rate")
            
            set1.setColor(UIColor.red)
            set1.setCircleColor(UIColor.red)
            
            /*
             let set2: LineChartDataSet = LineChartDataSet(values: ssdn, label: "heart.ssdn")
             
             set2.setColor(UIColor.blue)
             set2.setCircleColor(UIColor.blue)
             
             */
            
            let set3: LineChartDataSet = LineChartDataSet(values: yaw, label: "attitude.yaw")
            
            set3.setColor(UIColor.yellow)
            set3.setCircleColor(UIColor.yellow)
            
            let set4: LineChartDataSet = LineChartDataSet(values: pitch, label: "attitude.pitch")
            
            set4.setColor(UIColor.purple)
            set4.setCircleColor(UIColor.purple)
            
            let set5: LineChartDataSet = LineChartDataSet(values: roll, label: "attitude.roll")
            
            set5.setColor(UIColor.green)
            set5.setCircleColor(UIColor.green)
            
            let data = LineChartData(dataSets: [set1, /*set2, */ set3, set4, set5])
            
            //chartView.xAxis.valueFormatter = self
            
            //chartView.xAxis.axisRange = Double(self.samples.count)
            
            //chartView.xAxis.axisMaxLabels = Int(chartView.xAxis.axisRange) + 1
            //chartView.xAxis.axisMinLabels = Int(chartView.xAxis.axisRange) + 1
            
            chartView.data = data
            
            chartView.chartDescription?.enabled = false
            
            //chartView.centerViewTo(xValue: 1.00, yValue: 60.00, axis: YAxis.AxisDependency.left)
            
            //chartView.zoomIn()

    }
    
    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        return value.description
    }
    
    func export(samples: [[String:Any]]) -> UIActivityViewController {
        
        let fileName = "zazen.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "zazen.now, zazen.program, heart.rate, heart.sdnn, attitude.yaw, attitude.pitch, attitude.roll\n"
        
        for sample in samples {
            
            let line : String =
                "\(sample["zazen.now"]!),"  +
                    "\(sample["zazen.program"]!)," +
                    "\(sample["heart.rate"]!)," +
                    "\(sample["heart.sdnn"]!)," +
                    "\(sample["attitude.yaw"]!)," +
                    "\(sample["attitude.pitch"]!)," +
            "\(sample["attitude.roll"]!)"
            
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
