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
import XpringKit

enum CurrentInterval: Int {
    case hour = 0
    case day = 1
    case month = 2
    case year = 3
    case minute = 4
    case last = 5
    
    var interval: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .month: return .month
        case .year: return .year
        case .minute: return .minute
        case .last: return .hour
        }
    }
    
    var range: Int {
        switch self {
        case .hour: return 24
        case .day: return 7
        case .month: return 1
        case .year: return 1
        case .minute: return 1
        case .last: return 24
        }
    }
    
}

class OverviewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var currentInterval: CurrentInterval = .hour
    var isStartOverview = false
    
    let healthStore = ZBFHealthKit.healthStore
    let hkPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody)
    let hkType = HKObjectType.workoutType()
    var start = Date()
    var end = Date()
    var hrvData : LineChartData? = nil
    var mmData : LineChartData? = nil
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName: .reloadOverview, object: nil, queue: .main) { (notification) in
            self.tableView.reloadData()
        }
        
        checkHealthKit(isShow: true)
        
        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        
        setNeedsStatusBarAppearanceUpdate()
        
        setDate()
        
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = 1000.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.title = Settings.fullName
        self.navigationItem.prompt = Settings.email
        
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
        
        self.tableView.reloadData()
        
        /*
         * #todo: we were going to do phone notification in 4.20, but decide to do
         * watch only notifications, but this is where we would want to run a phone
         * notification request test.
         
         if !Settings.requestedNotificationPermission
         {
         self.showNotificationController()
         }
         
         */
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.mainInstance().time(event: "overview")
        
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
    
    func populateCharts(_ cell: OverviewTableViewCell) {
        
        cell.isHiddenHRV = true
        cell.isHiddenMM = true
        
        cell.durationView.setTitle("")
        
        cell.hrvChart.highlightValues([])
        cell.hrvChart.drawGridBackgroundEnabled = false
        cell.hrvChart.chartDescription?.enabled = false
        cell.hrvChart.autoScaleMinMaxEnabled = true
        cell.hrvChart.noDataText = ""
        
        cell.hrvChart.xAxis.drawGridLinesEnabled = false
        cell.hrvChart.xAxis.drawAxisLineEnabled = false
        cell.hrvChart.rightAxis.drawAxisLineEnabled = false
        cell.hrvChart.leftAxis.drawAxisLineEnabled = false
        
        let handler: ZBFHealthKit.SamplesHandler = { samples, error in
            
            DispatchQueue.main.async()
                {
                    
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
                        case .minute, .last: break
                        }
                        
                        let xaxis = XAxis()
                        xaxis.valueFormatter = formato
                        
                        cell.hrvChart.xAxis.valueFormatter = xaxis.valueFormatter
                        
                        cell.hrvChart.data!.highlightEnabled = true
                        self.hrvData?.notifyDataChanged()
                        cell.hrvChart.notifyDataSetChanged()
                        cell.hrvChart.fitScreen()
                        cell.isHiddenHRV = false
                        self.populateMMChart(cell: cell)
                        
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
    
    func populateHRV(_ cell: OverviewTableViewCell) {
        cell.hrvView.setTitle("")
        
        ZBFHealthKit.getHRVAverage(start: start, end: end)
        {
            (results, error) in
            
            if let value = results?.first?.value
            {
                DispatchQueue.main.async()
                    {
                        cell.hrvView.setTitle(Int(value.rounded()).description + "ms")
                }
            }
            else
            {
                DispatchQueue.main.async()
                    {
                        cell.hrvView.setTitle("--")
                }
            }
        }
    }
    
    func populateDatetimeSpan(_ cell: HeaderOverviewTableViewCell, _ currentInterval: CurrentInterval) {
        let date = Date()
        switch currentInterval {
        case .minute, .last: break
        case .hour:
            cell.dateTimeTitle.text = date.startOfDay.toZendoHeaderDayString
        case .day:
            cell.dateTimeTitle.text = date.startOfWeek.toZendoHeaderDayString + " - " + date.endOfWeek.toZendoHeaderDayString
        case .month:
            cell.dateTimeTitle.text = date.startOfMonth.toZendoHeaderMonthYearString
        case .year:
            cell.dateTimeTitle.text = date.startOfYear.toZendoHeaderYearString
        }
    }
    
    func populateMMChart(cell: OverviewTableViewCell) {
        
        cell.mmChart.highlightValues([])
        cell.mmChart.xAxis.drawGridLinesEnabled = false
        cell.mmChart.xAxis.drawAxisLineEnabled = false
        cell.mmChart.rightAxis.drawAxisLineEnabled = false
        cell.mmChart.leftAxis.drawAxisLineEnabled = false
        
        cell.mmChart.drawGridBackgroundEnabled = false
        cell.mmChart.chartDescription?.enabled = false
        cell.mmChart.autoScaleMinMaxEnabled = true
        cell.mmChart.noDataText = ""
        
        
        
        ZBFHealthKit.getMindfulMinutes(start: start, end: end, currentInterval: currentInterval) { samples, error in
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
                case .minute, .last: break
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
                case .hour: cell.durationView.setTitle(movingTotal.stringZendoTimeWatch)
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
        case .minute, .last: break
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
            
            self.setDate()
            
            self.tableView.reloadData()
            
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OverviewTableViewCell.reuseIdentifierCell, for: indexPath) as! OverviewTableViewCell
        
        if self.currentInterval == .hour {
            cell.durationView.zenInfoViewType = .totalMins
        } else {
            cell.durationView.zenInfoViewType = .minsAverage
        }
        
        populateHRV(cell)
        populateCharts(cell)
        
        return cell
    }
    
}


extension OverviewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 90.0
    }
    
}
