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
import Mixpanel

class ZazenController : UIViewController, IAxisValueFormatter {
    
    public var workout : HKWorkout!
    public var samples: [[String:Any]]!
    
    //@IBOutlet weak var minHRLabel: UILabel!
    //@IBOutlet weak var maxHRLabel: UILabel!
    //@IBOutlet weak var minHRVLabel: UILabel!
    //@IBOutlet weak var maxHRVLabel: UILabel!
    @IBOutlet weak var hrvImageView: UIImageView!
    
    @IBOutlet weak var bpmView: LineChartView!
    @IBOutlet weak var motionChart: LineChartView!
    @IBOutlet weak var hrvChart: LineChartView!
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
    
        super.viewWillAppear(animated)
        Mixpanel.mainInstance().track(event: "zazen_enter")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        Mixpanel.mainInstance().track(event: "zazen_exit")
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
                    
                    self.populateHrvChart()
                    self.populateSummary()
                    self.populateChart()
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
        
        let options : HKStatisticsOptions  = [HKStatisticsOptions.discreteAverage, HKStatisticsOptions.discreteMax, HKStatisticsOptions.discreteMin]

        var hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) { query, result, error in
                                            
                                            if(error != nil) {
                                                print(error.debugDescription);
                                            }
                                            
                                            if let value = result!.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                
                                                DispatchQueue.main.async() {
                                                    
                                                    //self.minHRLabel.text = String(value * 60.0)
                                                    
                                                }
                                            }
                                            
                                            if let value = result!.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/s")) {
                                                
                                                DispatchQueue.main.async() {
                                                    
                                                    //self.maxHRLabel.text = String(value * 60.0)
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
                                                
                                                //self.minHRVLabel.text = String(format: "%.1f", value)
                                                
                                                
                                            }
                                        }
                                        
                                        if let value = result!.maximumQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                            
                                            DispatchQueue.main.async() {
                                                
                                                //self.maxHRVLabel.text = String(format: "%.1f", value)
                                                
                                                
                                            }
                                        }
                                        
                                        if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                            
                                            DispatchQueue.main.async() {
                                                
                                                self.hrvImageView.image = ZBFHealthKit.generateImageWithText(size: self.hrvImageView.frame.size, text: Int(value).description, fontSize: 33.0)
                                                
                                                self.hrvImageView.setNeedsDisplay()
                                                
                                                UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                                                    
                                                    let scale = CGAffineTransform(scaleX: 1 - CGFloat(value/100), y: 1 - CGFloat(value/100))
                                                    
                                                    self.hrvImageView.transform = scale
                                                    
                                                    self.hrvImageView.transform = CGAffineTransform.identity
                                                    
                                                }, completion: nil )
                                                
                
                                            }
                                        }
                                        
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
    }
    
    func getChartData(key: String, scale: Double) -> LineChartData {
        
        var entries = [ChartDataEntry]()
        var communityEntries = [ChartDataEntry]()
        
        for(index, sample) in samples.enumerated() {
            
            if let value = sample[key] as? String {
                
                let y = Double(value)!
                let x = Double(index)
                
                if(y > 0.00) {
                    
                    let value = y * scale
                    
                    entries.append(ChartDataEntry(x: x, y: value ))

                    communityEntries.append(getCommunityDataEntry(key: key, interval: x, scale: scale))
                }
            }
        }
        
        let entryDataset = LineChartDataSet(values: entries, label: key)
        
        entryDataset.drawCirclesEnabled = false
        entryDataset.drawValuesEnabled = false
        entryDataset.setColor(UIColor.black)
        entryDataset.lineWidth = 3.0
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "sangha")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        communityDataset.setColor(UIColor.green)
        communityDataset.lineWidth = 3.0
        
        return LineChartData(dataSets: [entryDataset, communityDataset])
        
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
        
        var value = CommunityDataLoader.get(measure: key, at: interval)
        
        value = value * scale;
        
        return ChartDataEntry(x: interval, y: value)
    }
    
    func populateChart() {
        
        var rate = getChartData(key: "heart", scale: 60)
        
        //#todo: support v.002 schema
        if rate.entryCount == 0 {
            
            rate = getChartData(key: "rate", scale: 60)
        }
        
        bpmView.xAxis.valueFormatter = self
        bpmView.autoScaleMinMaxEnabled = true
        bpmView.noDataText = "No samples"
        bpmView.data?.setDrawValues(false)
        bpmView.chartDescription?.enabled = false
        
        bpmView.xAxis.avoidFirstLastClippingEnabled = true
        
        if(rate.entryCount > 0) {  bpmView.data = rate }
        //bpmView.animate(xAxisDuration: 3)
        
        let motion = getChartData(key: "motion", scale: 1)
        
        motionChart.xAxis.valueFormatter = self
        motionChart.xAxis.avoidFirstLastClippingEnabled = true
        motionChart.autoScaleMinMaxEnabled = true
        motionChart.noDataText = "No samples"
        motionChart.data?.setDrawValues(false)
        motionChart.chartDescription?.enabled = false
        
        if(motion.entryCount > 0) { motionChart.data = motion }
        //motionChart.animate(xAxisDuration: 3)
        
    }
    
    func populateHrvChart() {
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "hrv")
        
        let communityEntries = [ChartDataEntry]()
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "sangha")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        communityDataset.setColor(UIColor.green)
        communityDataset.lineWidth = 3.0
        
        dataset.drawCirclesEnabled = false
        dataset.lineWidth = 3.0
        dataset.setColor(UIColor.black)
        dataset.drawValuesEnabled = false
        
        self.hrvChart.data = LineChartData(dataSets: [dataset, communityDataset])
        
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
            
            let day = Calendar.current.date(byAdding: .hour, value: -24, to: self.workout.endDate)!
            
            statsCollection.enumerateStatistics(from: day, to: self.workout.endDate)
            {
                [unowned self] statistics, stop in
                
                var avgValue = 0.0
                
                if let avgQ = statistics.averageQuantity()
                {
                    avgValue = avgQ.doubleValue(for: HKUnit(from: "ms"))
                }
                
                let date = statistics.startDate
                
                let hours = Calendar.current.dateComponents([.hour], from: date, to: self.workout.endDate).hour!
                
                let entry = ChartDataEntry(x: Double(-hours), y: avgValue )
                
                self.hrvChart.data!.addEntry(entry, dataSetIndex: 0)
                
                let community = self.getCommunityDataEntry(key: "sdnn", interval: Double(-hours), scale: 1.0)
                
                self.hrvChart.data!.addEntry(community, dataSetIndex: 1)
                
            }
            
            DispatchQueue.main.sync() {
                
                self.hrvChart.notifyDataSetChanged()
            }
            
        }
        
        ZBFHealthKit.healthStore.execute(query)
        
        self.hrvChart.autoScaleMinMaxEnabled = true
        self.hrvChart.chartDescription?.enabled = false
        self.hrvChart.noDataText = "No samples"
       // self.hrvChart.animate(xAxisDuration: 3)
        
    }
    
    func stringForValue(_ value: Double,
                        axis: AxisBase?) -> String {
        
        let label = (value / 60)
        
        return String(format: "%.2f", label)
    }
    
    func export(samples: [[String:Any]]) -> UIActivityViewController {
        
        let fileName = "zazen.csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        var csvText = "start, end, now, hr, sdnn, motion\n"
        
        for sample in samples {
                        
            let line : String =
                "\(workout.startDate),"  +
                    "\(workout.endDate)," +
                    "\(sample["now"]!)," +
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
