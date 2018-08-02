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
    var samples: [[String:Any]]!
    
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
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
        
        motionChart.noDataText = ""
        bpmView.noDataText = ""
        hrvChart.noDataText = ""
        
        bpmView.autoScaleMinMaxEnabled = true
        motionChart.autoScaleMinMaxEnabled = true
        hrvChart.autoScaleMinMaxEnabled = true
        
        bpmView.chartDescription?.enabled = false
        hrvChart.chartDescription?.enabled = false
        motionChart.chartDescription?.enabled = false
        
        hrvChart.drawGridBackgroundEnabled = false
        bpmView.drawGridBackgroundEnabled = false
        motionChart.drawGridBackgroundEnabled = false
        
        bpmView.isHidden = true
        motionChart.isHidden = true
        hrvChart.isHidden = true
        
        self.durationLabel.text = ""
        self.dateTimeLabel.text = ""
        
        let hkPredicate = HKQuery.predicateForObjects(from: workout as HKWorkout)
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: true)
        
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query, results, error in
            
            if let results = results
            {
                DispatchQueue.main.async()
                {
                        self.samples =
                            results.map({ (sample) -> [String:Any] in
                                return sample.metadata!
                            })
                        
                        self.populateHrvChart()
                        
                }
            }
            else
            {
                print(error.debugDescription)
            }
            
        })
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
    @IBAction func export(_ sender: Any)
    {
        let vc : UIActivityViewController = export(samples: self.samples)
        
        present(vc, animated: true, completion: nil)
    }
    
    func populateSummary() {
        
        ZBFHealthKit.getHRVAverage(self.workout)
        {
            (results, error) in
            
            var value = 0.0
            
            if let results = results
            {
                value = results.first!.value
            }
            
                DispatchQueue.main.async()
                    {
                        
                        self.hrvImageView.image = ZBFHealthKit.generateImageWithText(size: self.hrvImageView.frame.size, text: Int(value).description, fontSize: 33.0)
                        
                        self.hrvImageView.setNeedsDisplay()
                        
                        UIView.animate(withDuration: 3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                            
                            let scale = CGAffineTransform(scaleX: 1 - CGFloat(value/100), y: 1 - CGFloat(value/100))
                            
                            self.hrvImageView.transform = scale
                            
                            self.hrvImageView.transform = CGAffineTransform.identity
                            
                            self.bpmView.isHidden = false
                            self.motionChart.isHidden = false
                            self.hrvChart.isHidden = false
                            
                            let minutes = (self.workout.duration / 60).rounded()
                            
                            self.durationLabel.text = "\(Int(minutes).description) min"
                            
                            self.dateTimeLabel.text = ZBFHealthKit.format(self.workout.endDate)
                            
                        })
                }

        }
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
            
            let label = (key == "heart" || key == "rate") ? "bpm" : key
            
            let entryDataset = LineChartDataSet(values: entries, label: label)
            
            entryDataset.drawCirclesEnabled = false
            entryDataset.drawValuesEnabled = false
            entryDataset.setColor(UIColor.black)
            entryDataset.lineWidth = 3.0
            
            let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
            
            communityDataset.drawCirclesEnabled = false
            communityDataset.drawValuesEnabled = false
            
            communityDataset.setColor(UIColor(red: 0.291, green: 0.307, blue: 0.752, alpha: 1.0))
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
            bpmView.xAxis.avoidFirstLastClippingEnabled = true
            
            if(rate.entryCount > 0)
            {
                bpmView.data = rate
            }
            
            let motion = getChartData(key: "motion", scale: 1)
            
            motionChart.xAxis.valueFormatter = self
            motionChart.xAxis.avoidFirstLastClippingEnabled = true
            
            if(motion.entryCount > 0) { motionChart.data = motion }
            
        }
        
        func populateHrvChart() {
            
            let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "hrv")
            
            let communityEntries = [ChartDataEntry]()
            
            let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
            
            communityDataset.drawCirclesEnabled = false
            communityDataset.drawValuesEnabled = false
            communityDataset.setColor(UIColor(red: 0.291, green: 0.307, blue: 0.752, alpha: 1.0))
            communityDataset.lineWidth = 3.0
            
            dataset.drawCirclesEnabled = false
            dataset.lineWidth = 3.0
            dataset.setColor(UIColor.black)
            dataset.drawValuesEnabled = false
            
            hrvChart.data = LineChartData(dataSets: [dataset, communityDataset])
            
            var interval = DateComponents()
            interval.hour = 1
            
            let yesterday = Calendar.current.date(byAdding: .hour, value: -24, to: self.workout.endDate)!
            
            let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
            
            let query = HKStatisticsCollectionQuery(quantityType: hkType,
                                                    quantitySamplePredicate: nil,
                                                    options: HKStatisticsOptions.discreteAverage,
                                                    anchorDate: yesterday,
                                                    intervalComponents: interval)
            
            query.initialResultsHandler = {
                
                query, results, error in
                
                let statsCollection = results!
                
                var entries : [Double : Double] = [:]
                
                statsCollection.enumerateStatistics(from: yesterday, to: self.workout.endDate )
                {
                    [unowned self] statistics, stop in
                    
                    var avgValue = 0.0
                    
                    if let avgQ = statistics.averageQuantity()
                    {
                        avgValue = avgQ.doubleValue(for: HKUnit(from: "ms"))
                    }
                    
                    let date = statistics.startDate
                    
                    let hours = Calendar.current.dateComponents([.hour], from: date, to: self.workout.endDate).hour!
                    
                    entries[Double(hours)] = avgValue
                    
                }
                
                let sorted = entries.sorted { $0.0 < $1.0 }
                
                DispatchQueue.main.async()
                    {
                        sorted.forEach {
                                (key, value) in
                                
                                if(value > 0 ) {
                                    
                                    let entry = ChartDataEntry(x: Double(key), y: value )
                                    
                                    print(entry)
                                    
                                    self.hrvChart.data!.addEntry(entry, dataSetIndex: 0)
                                    
                                }
                            
                                let community = self.getCommunityDataEntry(key: "sdnn", interval: Double(key), scale: 1.0)
                            
                                self.hrvChart.data!.addEntry(community, dataSetIndex: 1)
                        }
                        
                        self.hrvChart.notifyDataSetChanged()
                        self.populateChart()
                        self.populateSummary()
                        
                }
            }
            
            ZBFHealthKit.healthStore.execute(query)
            
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
