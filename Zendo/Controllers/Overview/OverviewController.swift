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

enum CurrentInterval: Int {
    case hour = 0
    case day = 1
    case month = 2
    case year = 3
    case all = 4
    
    var interval: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .month: return .month
        case .year: return .year
        case .all: return .day
        }
    }
    
    var range: Int {
        switch self {
        case .hour: return 24
        case .day: return 7
        case .month: return 1
        case .year: return 1
        case .all: return 7
        }
    }
    
}

class OverviewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var currentInterval: CurrentInterval = .hour
    var minDate = Date()
    
    let hkPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody)
    let hkType = HKObjectType.workoutType()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = 1000.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.locations = [0.0, 0.4]
        gradient.colors = [
            UIColor.zenDarkGreen.cgColor,
            UIColor.zenWhite.cgColor
        ]
        view.layer.insertSublayer(gradient, at: 0)
        view.backgroundColor = UIColor.zenWhite
        
        navigationController?.navigationBar.shadowImage = UIImage()
        
        NotificationCenter.default.addObserver(forName: .reloadOverview, object: nil, queue: .main) { (notification) in
            self.tableView.reloadData()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.mainInstance().time(event: "overview_enter")
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().time(event: "overview_exit")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .reloadOverview, object: nil)
    }
    
    func getSamples() {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let hkQuery = HKSampleQuery.init(sampleType: hkType,
                                         predicate: hkPredicate,
                                         limit: HealthKit.HKObjectQueryNoLimit,
                                         sortDescriptors: [sortDescriptor],
                                         resultsHandler: { query, results, error in
                                            
                                            if let error = error {
                                                print(error)
                                            } else {
                                                
                                                for sample in results! {
                                                    if sample.startDate < self.minDate {
                                                        self.minDate = sample.startDate
                                                    }
                                                }
                                                
                                                
                                                DispatchQueue.main.async() {
                                                    self.tableView.reloadData()
                                                }
                                            }
                                            
        })
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
    func populateCharts(_ cell: OverviewTableViewCell, _ currentInterval: CurrentInterval) {
        
        cell.hrvChart.drawGridBackgroundEnabled = false
        cell.hrvChart.chartDescription?.enabled = false
        cell.hrvChart.autoScaleMinMaxEnabled = true
        cell.hrvChart.noDataText = ""
        cell.hrvChart.xAxis.valueFormatter = self
        
        cell.hrvChart.xAxis.drawGridLinesEnabled = false
        cell.hrvChart.xAxis.drawAxisLineEnabled = false
        cell.hrvChart.rightAxis.drawAxisLineEnabled = false
        cell.hrvChart.leftAxis.drawAxisLineEnabled = false
        
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "ms")
        
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
        dataset.circleRadius = 4
        
        dataset.drawCircleHoleEnabled = true
        dataset.circleHoleRadius = 3
        
        // 00 - 0%
        // 80 - 50%
        let gradientColors = [
            ChartColorTemplates.colorFromString("#00277A69").cgColor,
            ChartColorTemplates.colorFromString("#80277A69").cgColor
        ]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataset.fillAlpha = 1
        dataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        cell.hrvChart.data?.clearValues()
        cell.hrvChart.data = LineChartData(dataSets: [dataset, communityDataset])
        
        let handler: ZBFHealthKit.SamplesHandler = { samples, error in
            var dateIntervals = [Double]()
            
            if let samples = samples {
                samples.sorted(by: <).forEach( { entry in
                    cell.hrvChart.data!.addEntry(ChartDataEntry(x: entry.key, y: entry.value), dataSetIndex: 0)
                    
                    let community = self.getCommunityDataEntry(key: "sdnn", interval: entry.key, scale: 1.0)
                    
                    cell.hrvChart.data!.addEntry(community, dataSetIndex: 1)
                    
                    print("populateHRVChart: \(entry)")
                    
                    dateIntervals.append(entry.key)
                })
            } else {
                cell.hrvChart.noDataText = "No HRV date"
                print(error.debugDescription)
            }
            
            DispatchQueue.main.async() {
                cell.hrvChart.notifyDataSetChanged()
                
                //@todo: this approach to getting dateIntervals fails when there is no HRV
                self.populateMMChart(cell: cell, dateIntervals: dateIntervals)
            }
        }
        
        var proirDate: Date!
        if currentInterval == .all {
            proirDate = minDate
        } else {
            proirDate = Calendar.current.date(byAdding: currentInterval.interval, value: -(currentInterval.range), to: Date())!
        }
        
        ZBFHealthKit.getHRVSamples(currentInterval: currentInterval, prior: proirDate, handler: handler)
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
        var value = CommunityDataLoader.get(measure: key, at: interval)
        value = value * scale
        
        return ChartDataEntry(x: interval, y: value)
    }
    
    func populateHRV(_ cell: OverviewTableViewCell, _  currentInterval: CurrentInterval) {
        cell.hrvView.title.text = "0ms"
        ZBFHealthKit.getHRVAverage(interval: currentInterval.interval, value: currentInterval.range) { results, error in
            
            if let results = results {
                let value = results.first!.value
                
                DispatchQueue.main.async() {
                    cell.hrvView.title.text = Int(value).description + "ms"
                }
            }}
    }
    
    func populateDatetimeSpan(_ cell: HeaderOverviewTableViewCell, _ currentInterval: CurrentInterval) {
        let end = Date()
        
        var prior: Date!
        if currentInterval == .all {
            prior = minDate
        } else {
            prior = Calendar.current.date(byAdding: currentInterval.interval, value: -(currentInterval.range), to: end)!
        }
        
        switch currentInterval {
        case .year, .all:
           
            cell.dateTimeTitle.text = prior.toZendoHeaderYearString + " - " + end.toZendoHeaderYearString
        default:
            cell.dateTimeTitle.text = prior.toZendoHeaderDayString + " - " + end.toZendoHeaderDayString
        }
    }
    
    func populateDurationTotal(_ cell: OverviewTableViewCell, _ currentInterval: CurrentInterval) {
        
        cell.durationView.title.text = "0sec"
        
        let end = Date()
        
        var prior: Date!
        if currentInterval == .all {
            prior = minDate
        } else {
            prior = Calendar.current.date(byAdding: currentInterval.interval, value: -(currentInterval.range), to: end)!
        }
        
        ZBFHealthKit.getMindfulMinutes(start: prior, end: end) { samples, error in
            if let samples = samples {
                var sum = 0.0
                
                samples.forEach { entry in
                    sum = sum + entry.value
                }
                
                
                DispatchQueue.main.async() {
                    cell.durationView.title.text = sum.stringZendoTime
                }
                
            } else {
                print(error.debugDescription)
            }
        }
    }
    
    func populateMMChart(cell: OverviewTableViewCell, dateIntervals: [Double]) {
        
        var mmData = [Double: Double]()
        
        var entryKey = 0.0
        
        cell.mmChart.xAxis.drawGridLinesEnabled = false
        cell.mmChart.xAxis.drawAxisLineEnabled = false
        cell.mmChart.rightAxis.drawAxisLineEnabled = false
        cell.mmChart.leftAxis.drawAxisLineEnabled = false
        
        cell.mmChart.drawGridBackgroundEnabled = false
        cell.mmChart.chartDescription?.enabled = false
        cell.mmChart.autoScaleMinMaxEnabled = true
        cell.mmChart.noDataText = ""
        cell.mmChart.xAxis.valueFormatter = self
        
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
        dataset.circleRadius = 4
        
        dataset.drawCircleHoleEnabled = true
        dataset.circleHoleRadius = 3
        
        // 00 - 0%
        // 80 - 50%
        let gradientColors = [ChartColorTemplates.colorFromString("#00277A69").cgColor,
                              ChartColorTemplates.colorFromString("#80277A69").cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        
        dataset.fillAlpha = 1
        dataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        cell.mmChart.data?.clearValues()
        cell.mmChart.data = LineChartData(dataSets: [dataset, communityDataset])
        
        let values = dateIntervals.sorted()
        
        var movingTotal = 0.0
        
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
                    
                    mmData.sorted(by: <).forEach { entry in
                        
                        movingTotal += entry.value
                        
                        DispatchQueue.main.async() {
                            
                            if entryKey <= entry.key {
                                cell.mmChart.data!.addEntry(ChartDataEntry(x: entry.key, y: entry.value), dataSetIndex: 0)
                                
                                let community = ChartDataEntry(x: entry.key, y: 30.0)
                                cell.mmChart.data!.addEntry(community, dataSetIndex: 1)
                                cell.mmChart.notifyDataSetChanged()
                                
                                entryKey = entry.key
                                
                            }
                            
                            //#todo(debt): pull in the v2 backend duration
                            //self.getCommunityDataEntry(key: "duration", interval: entry.key, scale: 1.0)
                            
                            // cell.durationView.title.text = movingTotal.stringZendoTime
                            //                            self.durationCache[self.currentInterval.interval] = movingTotal / Double(mmData.count)
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
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) ) {
//                Mixpanel.mainInstance().track(event: "new_session")
//            }
        }
        
        alert.addAction(ok)
        
        present(alert, animated: true)
    }
    
}

extension OverviewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return stringForValue(value, self.currentInterval.interval)
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

extension OverviewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderOverviewTableViewCell.reuseIdentifierCell) as! HeaderOverviewTableViewCell
        populateDatetimeSpan(cell, currentInterval)
        cell.backgroundColor = UIColor.zenDarkGreen
        for button in cell.buttons {
            button.layer.cornerRadius = 5.0
            button.backgroundColor = button.tag == currentInterval.rawValue ? UIColor.white : UIColor.clear
            button.setTitleColor(button.tag == currentInterval.rawValue ? UIColor.zenDarkGreen : UIColor.white, for: .normal)
        }
        cell.action = { tag in
            self.currentInterval = CurrentInterval(rawValue: tag)!
            
            if self.currentInterval == .all {
                self.getSamples()
            } else {
                self.tableView.reloadData()
            }
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OverviewTableViewCell.reuseIdentifierCell, for: indexPath) as! OverviewTableViewCell
        
        populateHRV(cell, currentInterval)
        populateCharts(cell, currentInterval)
        populateDurationTotal(cell, currentInterval)
        
        return cell
    }
    
}


extension OverviewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90.0
    }
    
}
