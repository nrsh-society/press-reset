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
        
        let view = super.view!
        
        let center_x = view.frame.width / 2
        let center_y = view.frame.height / 2
        let middle = CGPoint(x: center_x, y: center_y)
        
        let frame = CGRect(x: 88 - 20, y: 179 - 20, width: 40.0, height: 40.0)
        let bezier = UIBezierPath(ovalIn: frame)
        let shape = CAShapeLayer()
        
        shape.fillColor = UIColor.white.cgColor
        shape.path = bezier.cgPath
        
        let text = CATextLayer()
        text.string = Int(minutes).description
        text.foregroundColor = UIColor.black.cgColor
        text.font = UIFont(name: "Menlo-Bold", size: 22.0)
        text.fontSize = 22.0
        text.alignmentMode = kCAAlignmentCenter
        text.backgroundColor = UIColor.clear.cgColor
        text.frame = CGRect(x: 88  - 20 , y: 186 - 20 , width: 40.0, height: 40.0)
        
        view.layer.addSublayer(shape)
        view.layer.addSublayer(text)
        
    }
    
    func getChartData(key: String, scale: Double) -> LineChartData {
        
        var sum = 0.0
        var entries = [ChartDataEntry]()
        var avgEntries = [ChartDataEntry]()
        var communityEntries = [ChartDataEntry]()
        
        for(index, sample) in samples.enumerated() {
            
            if let value = sample[key] as? String {
                
                let y = Double(value)!
                let x = Double(index)
                
                if(y > 0.00) {
                    
                    let value = y * scale
                    
                    entries.append(ChartDataEntry(x: x, y: value ))
                    
                    sum = sum + value
                    
                    let avg = sum / Double(entries.count)
                    
                    avgEntries.append(ChartDataEntry(x: x, y: avg))
                    
                    communityEntries.append(getCommunityDataEntry(key: key, interval: x, scale: scale))
                }
            }
        }
        
        let entryDataset = LineChartDataSet(values: entries, label: key)
        
        entryDataset.drawCirclesEnabled = false
        entryDataset.drawValuesEnabled = false
        entryDataset.setColor(UIColor.lightGray)
        entryDataset.lineWidth = 2.0
        
        let avgDataset = LineChartDataSet(values: avgEntries, label: "avg")
        
        avgDataset.drawCirclesEnabled = false
        avgDataset.drawValuesEnabled = false
        avgDataset.setColor(UIColor.black)
        avgDataset.lineWidth = 3.0
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        communityDataset.setColor(UIColor.green)
        communityDataset.lineWidth = 3.0
        
        return LineChartData(dataSets: [entryDataset, avgDataset, communityDataset])
        
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
        
        chartView.xAxis.valueFormatter = self
        chartView.autoScaleMinMaxEnabled = true
        chartView.noDataText = "No samples"
        chartView.data?.setDrawValues(false)
        chartView.chartDescription?.enabled = false
        
        chartView.xAxis.avoidFirstLastClippingEnabled = true
        
        if(rate.entryCount > 0) {  chartView.data = rate }
        chartView.animate(xAxisDuration: 3)
        
        let motion = getChartData(key: "motion", scale: 1)
        
        motionChart.xAxis.valueFormatter = self
        motionChart.xAxis.avoidFirstLastClippingEnabled = true
        motionChart.autoScaleMinMaxEnabled = true
        motionChart.noDataText = "No samples"
        motionChart.data?.setDrawValues(false)
        motionChart.chartDescription?.enabled = false
        
        if(motion.entryCount > 0) { motionChart.data = motion }
        
    }
    
    func populateHrvChart() {
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "hrv")
        let avgset = LineChartDataSet(values: [ChartDataEntry](), label: "avg")
        
        var communityEntries = [ChartDataEntry]()
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        communityDataset.setColor(UIColor.green)
        communityDataset.lineWidth = 3.0
        
        dataset.drawCirclesEnabled = false
        dataset.lineWidth = 2.0
        dataset.setColor(UIColor.lightGray)
        dataset.drawValuesEnabled = false
        
        avgset.drawCirclesEnabled = false
        avgset.lineWidth = 3.0
        avgset.setColor(UIColor.black)
        avgset.drawValuesEnabled = false
        
        self.hrvChart.data = LineChartData(dataSets: [dataset, avgset, communityDataset])
        
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
                
                let community = self.getCommunityDataEntry(key: "sdnn", interval: Double(-days), scale: 1.0)
                
                self.hrvChart.data!.addEntry(community, dataSetIndex: 2)
                
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
