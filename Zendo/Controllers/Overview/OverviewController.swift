//
//  OverviewController.swift
//  Zendo
//
//  Created by Douglas Purdy on 7/8/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import Foundation
import HealthKit
import Mixpanel
import Charts

class OverviewController: UIViewController {
    
    var durationCache: [Calendar.Component: Double] = [:]
    var currentInterval: Calendar.Component = .hour
    
    @IBOutlet weak var mmChartView: UIView! {
        didSet {
            mmChartView.setShadowView()
        }
    }
    @IBOutlet weak var hrvChartView: UIView! {
        didSet{
            hrvChartView.setShadowView()
        }
    }
    @IBOutlet weak var mmChart: LineChartView!
    @IBOutlet weak var hrvChart: LineChartView!
    @IBOutlet weak var hrvImage: UIImageView!
    @IBOutlet weak var durationTitle: UILabel!
    @IBOutlet weak var datetimeTitle: UILabel!
    
    @IBAction func queryChanged(_ sender: Any) {
        let segment = sender as! UISegmentedControl
        
        let idx = segment.selectedSegmentIndex
        
        print(idx)
        
        switch idx {
        case 0:
            self.currentInterval = .hour
            populateHRVImage(.hour, 24)
            populateCharts(.hour, 24)
            populateDatetimeSpan(.hour, 24)
        //populateDurationAvg(.hour, 24)
        case 1:
            self.currentInterval = .day
            populateHRVImage(.day, 7)
            populateCharts(.day, 7)
            populateDatetimeSpan(.day, 7)
        //populateDurationAvg(.day, 7)
        case 2:
            self.currentInterval = .month
            populateHRVImage(.month, 1)
            populateCharts(.month, 1)
            populateDatetimeSpan(.month, 1)
        //populateDurationAvg(.month, 1)
        case 3:
            self.currentInterval = .year
            populateHRVImage(.year, 1)
            populateCharts(.year, 1)
            populateDatetimeSpan(.year, 1)
        //populateDurationAvg(.year, 1)
        default:break
        }
    }
    
    func showController(_ named: String) {
        Mixpanel.mainInstance().time(event: named + "_enter")
        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: named)
        
        present(controller, animated: true, completion: {
            Mixpanel.mainInstance().track(event: named + "_exit")
        });
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        
        if defaults.string(forKey: "runonce") == nil {
            defaults.set(true, forKey: "runonce")
            showController("welcome-controller")
        }
        
        let zendoFont = UIFont.zendo(font: .antennaRegular, size: 10.0)
        let arrayLineChart = [mmChart, hrvChart]
        
        for lineChart in arrayLineChart {
            lineChart?.noDataText = ""
            lineChart?.autoScaleMinMaxEnabled = true
            lineChart?.chartDescription?.enabled = false
            lineChart?.drawGridBackgroundEnabled = false
            lineChart?.pinchZoomEnabled = false
            
            let xAxis = lineChart?.xAxis
            xAxis?.drawGridLinesEnabled = false
            xAxis?.drawAxisLineEnabled = false
            xAxis?.labelPosition = .bottom
            xAxis?.labelTextColor = UIColor.zenGray
            xAxis?.labelFont = zendoFont
            
            let rightAxis = lineChart?.rightAxis
            rightAxis?.drawAxisLineEnabled = false
            rightAxis?.labelTextColor = UIColor.zenGray
            rightAxis?.labelPosition = .insideChart
            rightAxis?.labelFont = zendoFont
            rightAxis?.yOffset = -10.0
            
            let leftAxis = lineChart?.leftAxis
            leftAxis?.drawAxisLineEnabled = false
            leftAxis?.gridColor = UIColor.zenLightGray
            leftAxis?.drawLabelsEnabled = false
            
            lineChart?.setViewPortOffsets(left: 5, top: 0, right: 0, bottom: 45)
            lineChart?.highlightPerTapEnabled = false
            lineChart?.highlightPerDragEnabled = false
            lineChart?.doubleTapToZoomEnabled = false
            
            lineChart?.legend.textColor = UIColor(red: 0.05, green:0.2, blue: 0.15, alpha: 1)
            lineChart?.legend.font = UIFont.zendo(font: .antennaRegular, size: 10.0)
            lineChart?.legend.form = .circle
        }
        
        ZBFHealthKit.requestHealthAuth(handler: { success, error in
            
            DispatchQueue.main.async() {
                if success {
                    self.currentInterval = .hour
                    self.populateHRVImage(.hour, 24)
                    self.populateCharts(.hour, 24)
                    self.populateDatetimeSpan(.hour, 24)
                } else {
                    let image = UIImage(named: "healthkit")
                    let frame = self.view.frame
                    
                    let hkView = UIImageView(frame: frame)
                    hkView.image = image;
                    hkView.contentMode = .scaleAspectFit
                    
                    self.view.addSubview(hkView)
                    self.view.bringSubview(toFront: hkView)
                }
            }
        })
    }
    
    func populateCharts(_ interval: Calendar.Component, _ range: Int) {
        
        hrvChart.drawGridBackgroundEnabled = false
        hrvChart.chartDescription?.enabled = false
        hrvChart.autoScaleMinMaxEnabled = true
        hrvChart.noDataText = ""
        hrvChart.xAxis.valueFormatter = self
        print(hrvChart.scaleY)
        
        hrvChart.xAxis.drawGridLinesEnabled = false
        hrvChart.xAxis.drawAxisLineEnabled = false
        hrvChart.rightAxis.drawAxisLineEnabled = false
        hrvChart.leftAxis.drawAxisLineEnabled = false
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "bpm")
        
        let communityEntries = [ChartDataEntry]()
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        
        communityDataset.setColor(UIColor.zenRed)
        communityDataset.lineWidth = 1.5
        communityDataset.lineDashLengths = [10, 3]
        
        dataset.drawValuesEnabled = false
        dataset.setColor(UIColor.zenDarkGreen)
        dataset.lineWidth = 1.5
        
        dataset.drawCirclesEnabled = true
        dataset.setCircleColor(UIColor.zenDarkGreen)
        dataset.circleRadius = 3
        
        // 00 - 0%
        // 80 - 50%
        let gradientColors = [ChartColorTemplates.colorFromString("#00277A69").cgColor,
                              ChartColorTemplates.colorFromString("#80277A69").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataset.fillAlpha = 1
        dataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        
        hrvChart.data = LineChartData(dataSets: [dataset, communityDataset])
        
        let handler: ZBFHealthKit.SamplesHandler = { samples, error in
            var dateIntervals = [Double]()
            
            if let samples = samples {
                samples.sorted(by: <).forEach( { entry in
                    self.hrvChart.data!.addEntry(ChartDataEntry(x: entry.key, y: entry.value), dataSetIndex: 0)
                    
                    let community = self.getCommunityDataEntry(key: "sdnn", interval: entry.key, scale: 1.0)
                    
                    self.hrvChart.data!.addEntry(community, dataSetIndex: 1)
                    
                    print("populateHRVChart: \(entry)")
                    
                    dateIntervals.append(entry.key)
                })
            } else {
                self.hrvChart.noDataText = "No HRV date"
                print(error.debugDescription)
            }
            
            DispatchQueue.main.async() {
                self.hrvChart.notifyDataSetChanged()
                
                //@todo: this approach to getting dateIntervals fails when there is no HRV
                self.populateMMChart(dateIntervals: dateIntervals)
            }
        }
        
        ZBFHealthKit.getHRVSamples(interval: interval, value: range, handler: handler)
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
        var value = CommunityDataLoader.get(measure: key, at: interval)
        value = value * scale;
        
        return ChartDataEntry(x: interval, y: value)
    }
    
    func populateHRVImage(_ interval: Calendar.Component, _ range: Int) {
        ZBFHealthKit.getHRVAverage(interval: interval, value: range) { results, error in
            
            if let results = results {
                let value = results.first!.value
                
                DispatchQueue.main.async() {
                    self.hrvImage.image = ZBFHealthKit.generateImageWithText(size: self.hrvImage.frame.size, text: Int(value).description, fontSize: 33.0)
                    
                    self.hrvImage.setNeedsDisplay()
                    
                    UIView.animate(withDuration: 3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                        
                        let scale = CGAffineTransform(scaleX: 1 - CGFloat(value/100), y: 1 - CGFloat(value/100))
                        
                        self.hrvImage.transform = scale
                        self.hrvImage.transform = CGAffineTransform.identity
                    })
                }
            }}
    }
    
    func populateDatetimeSpan(_ interval: Calendar.Component, _ range: Int) {
        let end = Date()
        let prior = Calendar.current.date(byAdding: interval, value: -(range), to: end)!
        
        let dateFormatter = DateFormatter();
        
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY-MM-dd")
        
        let priorText = dateFormatter.string(from: prior)
        let endText = dateFormatter.string(from: end)
        
        datetimeTitle.text = "\(priorText) - \(endText)"
    }
    
    func populateDurationAvg(_ interval: Calendar.Component, _ range: Int) {
        
        if let cacheValue = durationCache[interval] {
            durationTitle.text = "\(Int(cacheValue)) min"
        } else {
            durationTitle.text = "Loading..."
            
            let end = Date()
            let prior = Calendar.current.date(byAdding: interval, value: -(range), to: end)!
            
            let dateInterval = DateInterval(start: prior, end: end)
            
            let days = (dateInterval.duration / 60 / 60 / 24)
            
            ZBFHealthKit.getMindfulMinutes(start: prior, end: end) { samples, error in
                if let samples = samples {
                    var sum = 0.0
                    
                    samples.forEach { entry in
                        sum = sum + entry.value
                    }
                    
                    let avg = (sum / 60) / days
                    
                    DispatchQueue.main.async() {
                        self.durationTitle.text = "\(Int(avg)) min"
                    }
                    
                    self.durationCache[interval] = avg
                } else {
                    print(error.debugDescription)
                }
            }
        }
    }
    
    func populateMMChart(dateIntervals: [Double]) {
        
        var mmData = [Double: Double]()
        
        var entryKey = 0.0
        
        durationTitle.text = "Loading..."
        
        mmChart.xAxis.drawGridLinesEnabled = false
        mmChart.xAxis.drawAxisLineEnabled = false
        mmChart.rightAxis.drawAxisLineEnabled = false
        mmChart.leftAxis.drawAxisLineEnabled = false
      
        mmChart.drawGridBackgroundEnabled = false
        mmChart.chartDescription?.enabled = false
        mmChart.autoScaleMinMaxEnabled = true
        mmChart.noDataText = ""
        mmChart.xAxis.valueFormatter = self
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "mins")
        
        let communityEntries = [ChartDataEntry]()
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        
        communityDataset.setColor(UIColor.zenRed)
        communityDataset.lineWidth = 1.5
        communityDataset.lineDashLengths = [10, 3]
        
        dataset.drawValuesEnabled = false
        dataset.setColor(UIColor.zenDarkGreen)
        dataset.lineWidth = 1.5
        
        dataset.drawCirclesEnabled = true
        dataset.setCircleColor(UIColor.zenDarkGreen)
        dataset.circleRadius = 3
        
        // 00 - 0%
        // 80 - 50%
        let gradientColors = [ChartColorTemplates.colorFromString("#00277A69").cgColor,
                              ChartColorTemplates.colorFromString("#80277A69").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataset.fillAlpha = 1
        dataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        mmChart.data = LineChartData(dataSets: [dataset, communityDataset])
        
        let values = dateIntervals.sorted()
        
        for (i, key) in values.enumerated() {
            let start = Date(timeIntervalSince1970: key)
            
            let idx = i + 1
            let last = (i == values.count - 1)
            
            let end = last ? Date() : Date(timeIntervalSince1970: values[idx])
            
            let days = DateInterval(start:start, end: end).duration / 60 / 60 / 24
            
            ZBFHealthKit.getMindfulMinutes(start: start, end: end) { samples, error in
                
                if let samples = samples {
                    var avg = 0.0
                    
                    if samples.count > 0 {
                        avg = (samples[samples.keys.first!]! / 60) / days
                    }
                    
                    mmData[start.timeIntervalSince1970] = avg
                }
                
                if mmData.count == dateIntervals.count {
                    var movingAvg = 0.0
                    
                    mmData.sorted(by: <).forEach { entry in
                        
                        movingAvg = movingAvg + entry.value
                        
                        DispatchQueue.main.async() {
                            
                            if entryKey <= entry.key {
                                self.mmChart.data!.addEntry(ChartDataEntry(x: entry.key, y: entry.value), dataSetIndex: 0)
                                
                                let community = ChartDataEntry(x: entry.key, y: 30.0)
                                self.mmChart.data!.addEntry(community, dataSetIndex: 1)
                                self.mmChart.notifyDataSetChanged()
                                
                                entryKey = entry.key
                                
                            }
                                                        
                            //#todo(debt): pull in the v2 backend duration
                            //self.getCommunityDataEntry(key: "duration", interval: entry.key, scale: 1.0)
                            
                            self.durationTitle.text = "\(Int(movingAvg) / mmData.count ) min"
                            self.durationCache[self.currentInterval] = movingAvg / Double(mmData.count)
                        }
                    }
                } else {
                    print(error.debugDescription)
                }
            }
        }
    }
    
    //#todo(debt): factor this into the zbfmodel + ui across controllers
    @IBAction func newSession(_ sender: Any) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        let store = HKHealthStore()
        
        store.startWatchApp(with: configuration) { success, error in
            guard success else {
                print (error.debugDescription)
                return
            }
        }
        
        Mixpanel.mainInstance().time(event: "new_session")
        
        let alert = UIAlertController(title: "Starting Watch App", message: "Deep Press + Exit when complete.", preferredStyle: .actionSheet)
        
        let ok = UIAlertAction(title: "Done", style: .default) { action in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) ) {
                Mixpanel.mainInstance().track(event: "new_session")
            }
        }
        
        alert.addAction(ok)
        
        present(alert, animated: true)
    }
    
}

extension OverviewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return stringForValue(value, self.currentInterval)
    }
    
    func stringForValue(_ value: Double, _ interval: Calendar.Component) -> String {
        let date = Date(timeIntervalSince1970: value)
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        
        switch interval {
        case .hour: dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
        case .day: dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
        case .month: dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
        case .year: dateFormatter.setLocalizedDateFormatFromTemplate("MM")
        default: dateFormatter.setLocalizedDateFormatFromTemplate("MM")
        }
        
        let localDate = dateFormatter.string(from: date)
        
        return localDate.description
    }
    
}
