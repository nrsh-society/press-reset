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

enum LineChartKey: String {
    case heart = "heart"
    case rate = "rate"
    case motion = "motion"
}

class HeaderZazenTableViewCell: UITableViewCell {
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var dateTimeLabel: UILabel!
}

class ZazenTableViewCell: UITableViewCell {
    @IBOutlet weak var durationView: UIView! {
        didSet {
            durationView.setShadowView()
        }
    }
    @IBOutlet weak var hrvView: UIView! {
        didSet {
            hrvView.setShadowView()
        }
    }
    @IBOutlet weak var bpmChartView: UIView! {
        didSet {
            bpmChartView.setShadowView()
        }
    }
    @IBOutlet weak var motionChartView: UIView! {
        didSet {
            motionChartView.setShadowView()
        }
    }
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var hrvLabel: UILabel!
    
    @IBOutlet weak var bpmChart: LineChartView!
    @IBOutlet weak var motionChart: LineChartView!
    // @IBOutlet weak var hrvChart: LineChartView!
    //    @IBOutlet weak var hrvChartView: UIView! {
    //        didSet {
    //            hrvChartView.setShadowView()
    //        }
    //    }
}

class ZazenController: UIViewController, IAxisValueFormatter {
    
    @IBOutlet weak var tableView: UITableView!
    
    var workout: HKWorkout!
    var samples = [[String: Any]]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 1000.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let hkPredicate = HKQuery.predicateForObjects(from: workout as HKWorkout)
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: true)
        
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, results, error in
            
            if let results = results {
                DispatchQueue.main.async() {
                    self.samples = results.map { sample -> [String: Any] in
                        return sample.metadata!
                    }
                    
                    
                    //                        self.populateChart()
                    //                        self.populateSummary()
                    self.tableView.reloadData()
                }
            } else {
                print(error.debugDescription)
            }
            
        })
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Mixpanel.mainInstance().track(event: "zazen_enter")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Mixpanel.mainInstance().track(event: "zazen_exit")
    }
    
    @IBAction func export(_ sender: Any) {
        let vc = export(samples: self.samples)
        present(vc, animated: true, completion: nil)
    }
    
    func populateSummary(cell: ZazenTableViewCell) {
        ZBFHealthKit.getHRVAverage(workout) { results, error in
            
            if let results = results {
                let value = results.first!.value
                
                DispatchQueue.main.async() {
                    cell.hrvLabel.text = Int(value).description + "ms"
                }
            } else {
                print(error.debugDescription)
            }
        }
    }
    
    func getChartData(_ lineChartKey: LineChartKey, scale: Double) -> LineChartData {
        
        var entries = [ChartDataEntry]()
        var communityEntries = [ChartDataEntry]()
        
        for (index, sample) in samples.enumerated() {
            
            if let value = sample[lineChartKey.rawValue] as? String {
                
                let y = Double(value)!
                let x = Double(index).rounded()
                
                if y > 0.00 {
                    let value = y * scale
                    
                    entries.append(ChartDataEntry(x: x, y: value))
                    communityEntries.append(getCommunityDataEntry(key: lineChartKey.rawValue, interval: x, scale: scale))
                }
            }
        }
        
        let label = (lineChartKey == .heart || lineChartKey == .rate) ? "bpm" : lineChartKey.rawValue
        
        let entryDataset = LineChartDataSet(values: entries, label: label)
        
        entryDataset.drawCirclesEnabled = false
        entryDataset.drawValuesEnabled = false
        entryDataset.setColor(UIColor.zenDarkGreen)
        entryDataset.lineWidth = 1.5
        
        
        
        switch lineChartKey {
        case .motion:
            entryDataset.drawCirclesEnabled = true
            entryDataset.setCircleColor(UIColor.zenDarkGreen)
            entryDataset.circleRadius = 3
            
            // 00 - 0%
            // 80 - 50%
            let gradientColors = [ChartColorTemplates.colorFromString("#00277A69").cgColor,
                                  ChartColorTemplates.colorFromString("#80277A69").cgColor]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
            
            entryDataset.fillAlpha = 1
            entryDataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
            entryDataset.drawFilledEnabled = true
        case .heart, .rate:
            entryDataset.mode = .cubicBezier
        }
        
        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        
        communityDataset.setColor(UIColor.zenRed)
        communityDataset.lineWidth = 1.5
        communityDataset.lineDashLengths = [10, 3]
        
        return LineChartData(dataSets: [entryDataset, communityDataset])
        
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
        var value = CommunityDataLoader.get(measure: key, at: interval)
        
        value = value * scale;
        
        return ChartDataEntry(x: interval, y: value)
    }
    
    func populateChart(cell: ZazenTableViewCell) {
        
        var rate = getChartData(.heart, scale: 60)
        
        //#todo: support v.002 schema
        if rate.entryCount == 0 {
            rate = getChartData(.rate, scale: 60)
        }
        
        cell.bpmChart.xAxis.valueFormatter = self
        cell.bpmChart.xAxis.avoidFirstLastClippingEnabled = true
        
        if rate.entryCount > 0 {
            cell.bpmChart.data = rate
            cell.bpmChartView.isHidden = false
        }
        
        let motion = getChartData(.motion, scale: 1)
        
        cell.motionChart.xAxis.valueFormatter = self
        cell.motionChart.xAxis.avoidFirstLastClippingEnabled = true
        
        if motion.entryCount > 0 {
            cell.motionChart.data = motion
            cell.motionChartView.isHidden = false
        }
        
    }
    //
    //    func populateHrvChart() {
    //
    //        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "hrv")
    //
    //        let communityEntries = [ChartDataEntry]()
    //
    //        let communityDataset = LineChartDataSet(values: communityEntries, label: "community")
    //
    //        communityDataset.drawCirclesEnabled = false
    //        communityDataset.drawValuesEnabled = false
    //        communityDataset.setColor(UIColor(red: 0.291, green: 0.307, blue: 0.752, alpha: 1.0))
    //        communityDataset.lineWidth = 3.0
    //
    //        dataset.drawCirclesEnabled = false
    //        dataset.lineWidth = 3.0
    //        dataset.setColor(UIColor.black)
    //        dataset.drawValuesEnabled = false
    //
    //        hrvChart.data = LineChartData(dataSets: [dataset, communityDataset])
    //
    //        var interval = DateComponents()
    //        interval.hour = 1
    //
    //        let yesterday = Calendar.current.date(byAdding: .hour, value: -24, to: self.workout.endDate)!
    //
    //        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
    //
    //        let query = HKStatisticsCollectionQuery(quantityType: hkType,
    //                                                quantitySamplePredicate: nil,
    //                                                options: HKStatisticsOptions.discreteAverage,
    //                                                anchorDate: yesterday,
    //                                                intervalComponents: interval)
    //
    //        query.initialResultsHandler = { query, results, error in
    //
    //            let statsCollection = results!
    //
    //            var entries = [Double: Double]()
    //
    //            statsCollection.enumerateStatistics(from: yesterday, to: self.workout.endDate) { [unowned self] statistics, stop in
    //
    //                var avgValue = 0.0
    //
    //                if let avgQ = statistics.averageQuantity() {
    //                    avgValue = avgQ.doubleValue(for: HKUnit(from: "ms"))
    //                }
    //
    //                let date = statistics.startDate
    //
    //                let hours = Calendar.current.dateComponents([.hour], from: date, to: self.workout.endDate).hour!
    //
    //                entries[Double(hours)] = avgValue
    //
    //            }
    //
    //            let sorted = entries.sorted { $0.0 < $1.0 }
    //
    //            DispatchQueue.main.async() { sorted.forEach { (key, value) in
    //
    //                if value > 0 {
    //                    let entry = ChartDataEntry(x: Double(key), y: value )
    //
    //                    print(entry)
    //
    //                    self.hrvChart.data!.addEntry(entry, dataSetIndex: 0)
    ////                    self.hrvChartView.isHidden = false
    //                }
    //
    //                let community = self.getCommunityDataEntry(key: "sdnn", interval: Double(key), scale: 1.0)
    //
    //                self.hrvChart.data!.addEntry(community, dataSetIndex: 1)
    //                }
    //
    //                self.hrvChart.notifyDataSetChanged()
    //                self.populateChart()
    //                self.populateSummary()
    //
    //            }
    //        }
    //
    //        ZBFHealthKit.healthStore.execute(query)
    //
    //    }
    
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        var valueStr = String(format: "%.2f", (value / 60))
        if valueStr.hasSuffix(".00") {
            valueStr = String(format: "%.0f", (value / 60))
        }
        return valueStr
    }
    
    func export(samples: [[String: Any]]) -> UIActivityViewController {
        
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

extension ZazenController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0.0 {
            tableView.backgroundColor = UIColor.zenDarkGreen
        } else {
            tableView.backgroundColor = UIColor.clear
        }
    }
    
}

extension ZazenController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderZazenTableViewCell.reuseIdentifierCell) as! HeaderZazenTableViewCell
        
        cell.timeView.backgroundColor = UIColor.zenDarkGreen
        cell.dateTimeLabel.text = workout.endDate.toZendoDetailsMonthString + " at " + workout.endDate.toZendoDetailsTimeString.lowercased()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ZazenTableViewCell.reuseIdentifierCell, for: indexPath) as! ZazenTableViewCell
        
        cell.durationLabel.text = workout.duration.stringZendoTime
        
        let zendoFont = UIFont.zendo(font: .antennaRegular, size: 10.0)
        
        let arrayLineChart = [cell.bpmChart, cell.motionChart]
        
        cell.bpmChartView.isHidden = true
        cell.motionChartView.isHidden = true
        //        hrvChartView.isHidden = true
        
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
        
        
        populateChart(cell: cell)
        populateSummary(cell: cell)
        
        return cell
    }
}
