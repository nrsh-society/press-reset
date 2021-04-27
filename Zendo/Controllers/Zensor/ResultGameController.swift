//
//  ResultGameController.swift
//  Zendo
//
//  Created by Boris Sedov on 20.07.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//


import UIKit
import HealthKit
import Mixpanel
import Charts


//@boris: finally got the labs experience to a place that is ok experience and code-wise. Trying to figure out the best way to getting this working in that flow now.
class ResultGameController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dateResult: UILabel!

    var currentInterval: CurrentInterval = .last
    var isStartOverview = false
    
    let healthStore = ZBFHealthKit.healthStore
    let hkPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody)
    let hkType = HKObjectType.workoutType()
    var start = Date()
    var end = Date()
    var hrvData: LineChartData? = nil
    var mmData: LineChartData? = nil
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        setNeedsStatusBarAppearanceUpdate()
        
        setDate()
        
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = 1000.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationController?.navigationBar.shadowImage = UIImage()
        
        NotificationCenter.default.addObserver(forName: .reloadOverview, object: nil, queue: .main) { (notification) in
            self.tableView.reloadData()
        }
        
        initHRVData()
        initMMData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !self.isStartOverview {
            
            ZBFHealthKit.getWorkouts(limit: 1) { [weak self] results in
                
                if results.count == 0 {
                    DispatchQueue.main.async() {
                        self?.tabBarController?.selectedIndex = 1
                        self?.isStartOverview = true
                    }
                }
                
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "overview")
        self.tableView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "overview")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .reloadOverview, object: nil)
    }
    
    @IBAction func onNewSession(_ sender: Any) {
        startingSession()
    }
    
    func initHRVData()
    {
        let dataset = LineChartDataSet(entries: [ChartDataEntry](), label: "ms")
        let communityDataset = LineChartDataSet(entries: [ChartDataEntry](), label: "community")
        
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
        
        dataset.highlightEnabled = true
        
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
        
        self.hrvData = LineChartData(dataSets: [dataset, communityDataset])
        
    }
    
    func initMMData()
    {
        let dataset = LineChartDataSet(entries: [ChartDataEntry](), label: "mins")
        let communityDataset = LineChartDataSet(entries: [ChartDataEntry](), label: "community")
        
        communityDataset.drawCirclesEnabled = false
        communityDataset.drawValuesEnabled = false
        communityDataset.highlightEnabled = false
        
        communityDataset.setColor(UIColor.zenRed)
        communityDataset.lineWidth = 1.5
        communityDataset.lineDashLengths = [10, 3]
        
        dataset.drawValuesEnabled = false
        dataset.setColor(UIColor.zenDarkGreen)
        dataset.lineWidth = 1.5
        dataset.highlightEnabled = true
        
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
        dataset.fill = Fill(linearGradient: gradient, angle: 90)
        dataset.drawFilledEnabled = true
        
        self.mmData = LineChartData(dataSets: [dataset, communityDataset])
        
    }
    
    func populateCharts(_ cell: ResultGameTableCell) {
        
        cell.isHiddenHRV = true
        cell.isHiddenMM = true
        
        DispatchQueue.main.async {
            cell.durationView.setTitle("")
        }
        
        DispatchQueue.main.async {
            cell.hrvChart.highlightValues([])
            cell.hrvChart.drawGridBackgroundEnabled = false
            cell.hrvChart.chartDescription?.enabled = false
            cell.hrvChart.autoScaleMinMaxEnabled = true
            cell.hrvChart.noDataText = ""
            
            cell.hrvChart.xAxis.drawGridLinesEnabled = false
            cell.hrvChart.xAxis.drawAxisLineEnabled = false
            cell.hrvChart.rightAxis.drawAxisLineEnabled = false
            cell.hrvChart.leftAxis.drawAxisLineEnabled = false
        }
        
        let handler: ZBFHealthKit.SamplesHandler = { samples, error in
            
            DispatchQueue.main.async {
                    
                    let dataset = self.hrvData?.getDataSetByIndex(0)!
                    let communityDataset = self.hrvData?.getDataSetByIndex(1)!
                    dataset?.clear()
                    communityDataset?.clear()
                    
                    if cell.hrvChart.data == nil
                    {
                        cell.hrvChart.data = self.hrvData
                    }
                    
                    if let samples = samples {
                        
                        samples.sorted(by: <).forEach( { entry in
                            
                            if entry.value > 0.0 {
                                _ = dataset?.addEntry(ChartDataEntry(x: entry.key, y: entry.value))
                            }
                            
                            _ = communityDataset?.addEntry(self.getCommunityDataEntry(key: "sdnn", interval: entry.key, scale: 1.0))
                            
                        })
                        
                        var formato = MMChartFormatter()
                        
                        switch self.currentInterval {
                        case .last:
                            //                    cell.mmChart.xAxis.setLabelCount(12, force: true)
//                            formato = MMChartFormatterHour()
                            break
                        case .hour:
                            cell.hrvChart.xAxis.setLabelCount(12, force: true)
                            formato = MMChartFormatterHour()
                        case .day:
                            cell.hrvChart.xAxis.setLabelCount(7, force: true)
                            formato = MMChartFormatterDay()
                        case .month:
                            cell.hrvChart.xAxis.setLabelCount(15, force: true)
                            formato = MMChartFormatterHour()
                        case .year:
                            cell.hrvChart.xAxis.setLabelCount(12, force: true)
                            formato = MMChartFormatterYear()
                        case .minute: break
                        }
                        
                        let xaxis = XAxis()
                        xaxis.valueFormatter = formato
                        
                        cell.hrvChart.xAxis.valueFormatter = xaxis.valueFormatter
                        
                        cell.hrvChart.data!.highlightEnabled = true
                        self.hrvData?.notifyDataChanged()
                        cell.hrvChart.notifyDataSetChanged()
                        cell.hrvChart.fitScreen()
                        cell.isHiddenHRV = false
                    }
            }
        }
        
        ZBFHealthKit.getHRVSamples(start: start, end: end, currentInterval: currentInterval, handler: handler)
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
        var value = CommunityDataLoader.get(measure: key, at: interval)
        value = value * scale
        
        return ChartDataEntry(x: interval, y: value.rounded())
    }
    
    
    func populateHRV(_ cell: ResultGameTableCell, start: Date, end: Date) {
        DispatchQueue.main.async() {
            self.dateResult.text = start.toZendoHeaderDayTimeString
            cell.hrvView.setTitle("")
        }
        ZBFHealthKit.getHRVAverage(start: start, end: end) { results, error in
            
            if let value = results?.first?.value {
                
                DispatchQueue.main.async() {
                    cell.hrvView.setTitle(Int(value.rounded()).description + "ms")
                }
                
            } else {
                
                DispatchQueue.main.async() {
                    cell.hrvView.setTitle("--")
                }
                
            }
        }
    }
    
    func populateMMChart(cell: ResultGameTableCell) {
        
        DispatchQueue.main.async() {
            cell.mmChart.highlightValues([])
            cell.mmChart.xAxis.drawGridLinesEnabled = false
            cell.mmChart.xAxis.drawAxisLineEnabled = false
            cell.mmChart.rightAxis.drawAxisLineEnabled = false
            cell.mmChart.leftAxis.drawAxisLineEnabled = false
            
            cell.mmChart.drawGridBackgroundEnabled = false
            cell.mmChart.chartDescription?.enabled = false
            cell.mmChart.autoScaleMinMaxEnabled = true
            cell.mmChart.noDataText = ""
        }
        
        ZBFHealthKit.getMindfulMinutesLast(start: start, end: end, currentInterval: currentInterval) { (samples, error, startDate, endDate) in
            
            if let startDate = startDate, let endDate = endDate {
                self.start = startDate
                self.end = endDate
                self.populateCharts(cell)
                self.populateHRV(cell, start: startDate, end: endDate)
            }            
            
            DispatchQueue.main.async() {
                
                let dataset = self.mmData?.getDataSetByIndex(0)!
                let communityDataset = self.mmData?.getDataSetByIndex(1)!
                dataset?.clear()
                communityDataset?.clear()
                
                if cell.mmChart.data == nil
                {
                    cell.mmChart.data = self.mmData
                }
                
                cell.isHiddenMM = true
                cell.durationView.setTitle("")
                
                var movingTotal = 0.0
                var movingTotalCount = 0.0
                
                if let samples = samples {
                    
                    let sam = samples.sorted(by: <)
                    
                    for var entry in sam {
                        
                        movingTotal += entry.value
                        
                        if entry.value > 0.0 {
                            movingTotalCount += 1
                        }
                        entry.value = (entry.value / 60.0).rounded()
                        
                        if entry.value > 0.0 {
                            _ = dataset?.addEntry(ChartDataEntry(x: entry.key, y: entry.value))
                        }
                        let community = ChartDataEntry(x: entry.key, y: 30.0)
                        _ = communityDataset?.addEntry(community)
                    }
                }
                
                var formato = MMChartFormatter()
                let formatoValue = MMChartValueFormatter()
                let xaxisValue = XAxis()
                xaxisValue.valueFormatter = formatoValue
                
                switch self.currentInterval {
                case .last:
                    cell.mmChart.xAxis.setLabelCount(samples?.count ?? 0, force: true)
                    formato = MMChartFormatterHour()
                case .minute: break
                case .hour:
                    cell.mmChart.xAxis.setLabelCount(12, force: true)
                    formato = MMChartFormatterHour()
                case .day:
                    cell.mmChart.xAxis.setLabelCount(7, force: true)
                    formato = MMChartFormatterDay()
                case .month:
                    cell.mmChart.xAxis.setLabelCount(15, force: true)
                    formato = MMChartFormatterHour()
                case .year:
                    cell.mmChart.xAxis.setLabelCount(12, force: true)
                    formato = MMChartFormatterYear()
                }
                
                let xaxis = XAxis()
                xaxis.valueFormatter = formato
                
                cell.mmChart.xAxis.valueFormatter = xaxis.valueFormatter
                cell.mmChart.rightAxis.valueFormatter = xaxisValue.valueFormatter
                
                cell.mmChart.data!.highlightEnabled = true
                self.mmData?.notifyDataChanged()
                cell.mmChart.notifyDataSetChanged()
                cell.mmChart.fitScreen()
                cell.isHiddenMM = false
                
                switch self.currentInterval {
                case .hour, .minute: cell.durationView.setTitle(movingTotal.stringZendoTimeWatch)
                default:
                    let avg = movingTotal / movingTotalCount
                    if avg.isNaN {
                        cell.durationView.setTitle(0.0.stringZendoTimeWatch)
                    } else {
                        cell.durationView.setTitle(avg.stringZendoTimeWatch)
                    }
                }
            }
            
        }
        
    }
    
    func setDate() {
        let date = Date()
        
        switch self.currentInterval {
        case .minute: break
        case .last:
            self.start = date.addingTimeInterval(-60*60*24)
            self.end = date
        case .hour:
            self.start = date.startOfDay
            self.end = date.endOfDay
        case .day:
            self.start = date.startOfWeek
            self.end = date.endOfWeek
        case .month:
            self.start = date.startOfMonth
            self.end = date.endOfMonth
        case .year:
            self.start = date.startOfYear
            self.end = date.endOfYear
        }
        
    }
    
}

extension ResultGameController: IAxisValueFormatter {
    
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

extension ResultGameController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ResultGameTableCell.reuseIdentifierCell, for: indexPath) as! ResultGameTableCell
        
        if self.currentInterval == .hour || self.currentInterval == .last {
            cell.durationView.zenInfoViewType = .totalMins
        } else {
            cell.durationView.zenInfoViewType = .minsAverage
        }
        
        
        populateMMChart(cell: cell)
        
        return cell
    }
    
}


extension ResultGameController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90.0
    }
    
}

extension ResultGameController {
    
    static func loadFromStoryboard() -> ResultGameController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultGameController") as! ResultGameController
    }
    
}

