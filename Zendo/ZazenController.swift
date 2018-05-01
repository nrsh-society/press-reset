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
    
    @IBOutlet weak var minHRLabel: UILabel!
    @IBOutlet weak var maxHRLabel: UILabel!
    @IBOutlet weak var minHRVLabel: UILabel!
    @IBOutlet weak var maxHRVLabel: UILabel!
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var motionChart: LineChartView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var hrvChart: LineChartView!
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
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
                    self.populateHrvChart()
                    
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
                                                    
                                                    self.minHRLabel.text = String(value * 60.0)
                                                    
                                                }
                                            }
                                            
                                            if let value = result!.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                
                                                DispatchQueue.main.async() {
                                                    
                                                    self.maxHRLabel.text = String(value * 60.0)
                                                }
                                            }
                                            
        }
        
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
        hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)
        
        hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: workout.endDate, options: .strictEndDate)
        
        hkQuery = HKStatisticsQuery(quantityType: hkType,
                                    quantitySamplePredicate: hkPredicate,
                                    options: options) { query, result, error in
                                        
                                        if(error != nil) {
                                            print(error.debugDescription);
                                        }
                                        
                                        if let value = result!.minimumQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                            
                                            DispatchQueue.main.async() {
                                                
                                                self.minHRVLabel.text = String(format: "%.1f", value)
                                                
                                                
                                            }
                                        }
                                        
                                        if let value = result!.maximumQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                            
                                            DispatchQueue.main.async() {
                                                
                                                self.maxHRVLabel.text = String(format: "%.1f", value)
                                                
                                                
                                            }
                                        }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
        let minutes = (workout.duration / 60).rounded()
        
        durationLabel.text = Int(minutes).description;
        
    }
    
    func getChartDataSet(key: String, color: UIColor, scale: Double) -> LineChartDataSet {
        
        var entries = [ChartDataEntry]()
        
        for(index, sample) in samples.enumerated() {
            
            if let value = sample[key] as? String {
                
                let y = Double(value)!
                
                if(y > 0.00) {
                    
                    entries.append(ChartDataEntry(x: Double(index), y: y * scale ))
                }
            }
            
        }
        
        let retval = LineChartDataSet(values: entries, label: key)
        
        retval.setColor(color)
        
        retval.drawCirclesEnabled = false
        
        return retval
        
    }
    
    func populateChart() {
        
        var rate = getChartDataSet(key: "heart", color: UIColor.black, scale: 60)
        
        //#todo: support v.002 schema
        if rate.entryCount == 0 {
            
            rate = getChartDataSet(key: "rate", color: UIColor.lightGray, scale: 60)
        }
        
        rate.lineWidth = 3.0
        
        let motion = getChartDataSet(key: "motion", color: UIColor.lightGray, scale: 1)
        
        motion.lineWidth = 3.0
        
        let data1 = LineChartData(dataSets: [rate])
        let data2 = LineChartData(dataSets: [motion])
        
        chartView.xAxis.valueFormatter = self
        motionChart.xAxis.valueFormatter = self
        
        if(rate.entryCount > 0) {  chartView.data = data1 }
        if(motion.entryCount > 0) { motionChart.data = data2 }
        
        chartView.autoScaleMinMaxEnabled = true
        chartView.chartDescription?.enabled = false
        chartView.noDataText = "No samples"
        chartView.animate(xAxisDuration: 3)
        
        motionChart.autoScaleMinMaxEnabled = true
        motionChart.chartDescription?.enabled = false
        motionChart.noDataText = "No samples"
        motionChart.animate(xAxisDuration: 3)
        
    }
    
    func populateHrvChart() {
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "hrv")
        
        let avgset = LineChartDataSet(values: [ChartDataEntry](), label: "avg")
        
        dataset.drawCirclesEnabled = false
        dataset.lineWidth = 3.0
        dataset.setColor(UIColor.lightGray)
        dataset.drawValuesEnabled = false
        
        avgset.drawCirclesEnabled = false
        avgset.lineWidth = 3.0
        avgset.setColor(UIColor.black)
        avgset.drawValuesEnabled = false
        
        self.hrvChart.data = LineChartData(dataSets: [dataset, avgset])
        
        self.hrvChart.drawGridBackgroundEnabled = false
        
        var interval = DateComponents()
        interval.day = 1
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: workout.endDate)!
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let query = HKStatisticsCollectionQuery(quantityType: hkType,
                                                quantitySamplePredicate: nil,
                                                options: HKStatisticsOptions.discreteAverage,
                                                anchorDate: yesterday,
                                                intervalComponents: interval)
        
        // Set the results handler
        query.initialResultsHandler = {
            
            query, results, error in
            
            let statsCollection = results!
            
            let quarter = Calendar.current.date(byAdding: .day, value: -90, to: self.workout.endDate)!
            
            var hrvsum = 0.0
            
            statsCollection.enumerateStatistics(from: quarter, to: self.workout.endDate) { [unowned self] statistics, stop in
                
                var minValue = 0.0
                var maxValue = 0.0
                var avgValue = 0.0
                
                if let avgQ = statistics.averageQuantity() {
                    
                    avgValue = avgQ.doubleValue(for: HKUnit(from: "ms"))
                    
                }
                
                if let minQ = statistics.minimumQuantity() {
                    
                    minValue = minQ.doubleValue(for: HKUnit(from: "ms"))
                }
                
                
                if let maxQ = statistics.maximumQuantity() {
                    
                    maxValue = maxQ.doubleValue(for: HKUnit(from: "ms"))
                }
                
                
                let date = statistics.startDate
                
                let days = Calendar.current.dateComponents([.day], from: date, to: self.workout.endDate).day!
                
                let entry = ChartDataEntry(x: Double(-days), y: avgValue )
                
                self.hrvChart.data!.addEntry(entry, dataSetIndex: 0)
                
                let num = Double((self.hrvChart.data?.dataSets[0].entryCount)!)
                
                hrvsum = hrvsum + avgValue
                
                let avg = ChartDataEntry(x: Double(-days), y:  hrvsum / num )
                
                self.hrvChart.data!.addEntry(avg, dataSetIndex: 1)
                
                DispatchQueue.main.async() {
                    self.hrvChart.notifyDataSetChanged()
                }
                
            }
        }
        
        ZBFHealthKit.healthStore.execute(query)
        
        self.hrvChart.autoScaleMinMaxEnabled = true
        self.hrvChart.chartDescription?.enabled = false
        self.hrvChart.noDataText = "No samples"
        self.hrvChart.animate(xAxisDuration: 3)
        
    }
    
    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        
        let label = (value / 60)
        
        return String(format: "%.2f", label)
    }
    
    func export(samples: [[String:Any]]) -> UIActivityViewController {
        
        let fileName = "zazen.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "now, hr, sdnn, motion\n"
        
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
