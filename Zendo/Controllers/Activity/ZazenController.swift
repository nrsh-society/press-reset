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

class HeaderZazenTableViewCell: UITableViewCell
{
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var dateTimeLabel: UILabel!
}

class ZazenTableViewCell: UITableViewCell
{
    @IBOutlet weak var durationView: ZenInfoView!
    {
        didSet
        {
            durationView.zenInfoViewType = .totalMins
            durationView.setTitle("")
        }
    }
    
    @IBOutlet weak var hrvView: ZenInfoView!
    {
        didSet {
            hrvView.zenInfoViewType = .totalHrv
        }
    }
    
    @IBOutlet weak var bpmChartView: UIView!
    {
        didSet {
            bpmChartView.setShadowView()
        }
    }
    
    @IBOutlet weak var motionChartView: UIView!
    {
        didSet {
            motionChartView.setShadowView()
        }
    }
    
    @IBOutlet weak var bpmChart: LineChartView!
    @IBOutlet weak var motionChart: LineChartView!
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        let zendoFont = UIFont.zendo(font: .antennaRegular, size: 10.0)
        
        let arrayLineChart = [bpmChart, motionChart]
        
        for lineChart in arrayLineChart
        {
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
            lineChart?.layoutIfNeeded()
            let count = Int(((lineChart?.frame.size.width ?? 300) / 51.2).rounded())
            xAxis?.setLabelCount(count, force: true)
            
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
            
            lineChart?.setViewPortOffsets(left: 10, top: 10, right: 10, bottom: 45)
            lineChart?.highlightPerTapEnabled = false
            lineChart?.highlightPerDragEnabled = false
            lineChart?.doubleTapToZoomEnabled = false
            
            lineChart?.legend.textColor = UIColor(red: 0.05, green:0.2, blue: 0.15, alpha: 1)
            lineChart?.legend.font = UIFont.zendo(font: .antennaRegular, size: 10.0)
            lineChart?.legend.form = .circle
        }
    }
    
}

class ZazenController: UIViewController
{
    
    @IBOutlet weak var tableView: UITableView!
    
    var workout: HKSample!
    var samples = [[String: Any]]()
    
    lazy var share: Double = {
        let duration = workout.endDate.timeIntervalSince1970 - workout.startDate.timeIntervalSince1970
        return duration / Double(samples.count)
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }
        
        tableView.backgroundColor = UIColor.clear
        tableView.estimatedRowHeight = 1000.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.locations = [0.0, 0.25]
        gradient.colors = [
            UIColor.zenDarkGreen.cgColor,
            UIColor.zenWhite.cgColor
        ]
        view.layer.insertSublayer(gradient, at: 0)
        view.backgroundColor = UIColor.zenWhite
        
        navigationController?.navigationBar.shadowImage = UIImage()
        
        if let metadata = workout.metadata {
            let timeArray = (metadata[MetadataType.time.rawValue] as! String).components(separatedBy: "/")
            let nowArray = (metadata[MetadataType.now.rawValue] as! String).components(separatedBy: "/")
            let motionArray = (metadata[MetadataType.motion.rawValue] as! String).components(separatedBy: "/")
            let sdnnArray = (metadata[MetadataType.sdnn.rawValue] as! String).components(separatedBy: "/")
            let heartArray = (metadata[MetadataType.heart.rawValue] as! String).components(separatedBy: "/")
            let pitchArray = (metadata[MetadataType.pitch.rawValue] as! String).components(separatedBy: "/")
            let rollArray = (metadata[MetadataType.roll.rawValue] as! String).components(separatedBy: "/")
            let yawArray = (metadata[MetadataType.yaw.rawValue] as! String).components(separatedBy: "/")
            
            for (index, _) in timeArray.enumerated() {
                samples.append([
                    MetadataType.time.rawValue: timeArray[index],
                    MetadataType.now.rawValue: nowArray[index],
                    MetadataType.motion.rawValue: motionArray[index],
                    MetadataType.sdnn.rawValue: sdnnArray[index],
                    MetadataType.heart.rawValue: heartArray[index],
                    MetadataType.pitch.rawValue: pitchArray[index],
                    MetadataType.roll.rawValue: rollArray[index],
                    MetadataType.yaw.rawValue: yawArray[index]
                    ])
            }
            
        } else {
            //#todo(bug): watchos 5, beta 5 introduced a bug that causes this query not to work now
            //so we are switching to a date range
            //let hkPredicate = HKQuery.predicateForObjects(from: workout as HKWorkout)
            let hkPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
            
            
            let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            
            let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { query, results, error in
                
                if let results = results {
                    DispatchQueue.main.async() {
                        self.samples = results.map { sample -> [String: Any] in
                            return sample.metadata ?? [:]
                        }
                        
                        self.tableView.reloadData()
                    }
                } else {
                    print(error.debugDescription)
                }
                
            })
            
            ZBFHealthKit.healthStore.execute(hkQuery)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        Mixpanel.mainInstance().time(event: "detail")
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        Mixpanel.mainInstance().track(event: "detail")
    }
    
    static func loadFromStoryboard() -> ZazenController
    {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "zazen-controller") as! ZazenController
        
        return controller
    }
    
    @IBAction func export(_ sender: Any)
    {
        let vc = export(samples: self.samples)
        present(vc, animated: true, completion: nil)
    }
    
    func populateSummary(cell: ZazenTableViewCell)
    {
        cell.hrvView.setTitle("")
        
        ZBFHealthKit.getHRVAverage(start: workout.startDate, end: workout.endDate)
        {
            results, error in
            
            if let value = results?.first?.value
        //if let value = workout.hrv
            {
                DispatchQueue.main.async()
                {
                    if(value > 0)
                    {
                        cell.hrvView.setTitle(Int(value.rounded()).description + "ms")
                    }
                    else
                    {
                        cell.hrvView.setTitle("--")
                    }
                }
            }
        else
        {
                DispatchQueue.main.async()
                {
                    cell.hrvView.setTitle("--")
                    
                }
               // print(error.debugDescription)
        }
    }
    }
    
    func getChartData(_ lineChartKey: LineChartKey, scale: Double) -> LineChartData {
        
        var entries = [ChartDataEntry]()
        var communityEntries = [ChartDataEntry]()
        
        for (index, sample) in samples.enumerated() {
            
            if let value = sample[lineChartKey.rawValue] as? String {
                
                let y = Double(value)!
                
                if y > 0.00 {
                    
                    let value = y * scale
                    
                    let timeInterval: TimeInterval
                    
                    if let time = sample[MetadataType.time.rawValue] as? String
                    {
                        timeInterval = TimeInterval(time)! - workout.startDate.timeIntervalSince1970
                    }
                    else
                    {
                        let x = Double(index).rounded()
                        timeInterval = share * x
                        
                    }
                    
                    entries.append(ChartDataEntry(x: timeInterval, y: value))
                    communityEntries.append(getCommunityDataEntry(key: lineChartKey.rawValue, interval: timeInterval, scale: scale))
                }
            }
        }
        
        let label = (lineChartKey == .heart || lineChartKey == .rate) ? "bpm" : lineChartKey.rawValue
        
        let entryDataset = LineChartDataSet(entries: entries, label: label)
        
        entryDataset.drawCirclesEnabled = false
        entryDataset.drawValuesEnabled = false
        entryDataset.setColor(UIColor.zenDarkGreen)
        entryDataset.lineWidth = 1.5
        
        switch lineChartKey {
        case .motion:
            let gradientColors = [
                ChartColorTemplates.colorFromString("#00277A69").cgColor,  // 00 - 0%
                ChartColorTemplates.colorFromString("#80277A69").cgColor   // 80 - 50%
            ]
            let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
            
            entryDataset.fillAlpha = 1
            entryDataset.fill = Fill(linearGradient: gradient, angle: 90) //.linearGradient(gradient, angle: 90)
            entryDataset.drawFilledEnabled = true
        case .heart, .rate:
            entryDataset.mode = .cubicBezier
        }
        
        let communityDataset = LineChartDataSet(entries: communityEntries, label: "community")
        
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
  
    func export(samples: [[String: Any]]) -> UIActivityViewController {
        
        let now = Date().toZazenDateString
        let fileName = "\(now) zazen.csv"
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


extension ZazenController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderZazenTableViewCell.reuseIdentifierCell) as! HeaderZazenTableViewCell
        
        cell.timeView.backgroundColor = UIColor.zenDarkGreen
        
        cell.dateTimeLabel.text = workout.endDate.toZendoDetailsMonthString + " at " + workout.endDate.toZendoDetailsTimeString.lowercased()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: ZazenTableViewCell.reuseIdentifierCell, for: indexPath) as! ZazenTableViewCell
        
        cell.durationView.setTitle(workout.duration.stringZendoTimeWatch)
        
        cell.bpmChartView.isHidden = true
        cell.motionChartView.isHidden = true
        
        populateChart(cell: cell)
        populateSummary(cell: cell)
        
        return cell
    }
}


extension ZazenController: IAxisValueFormatter
{
    func stringForValue(_ value: Double, axis: AxisBase?) -> String
    {
        return value.stringZendoTimeWatch
    }

}

extension HKSample
{
    var duration: TimeInterval!
    {
        get
        {
            let duration = self.endDate.timeIntervalSince1970 - self.startDate.timeIntervalSince1970
            return duration
        }
    }
    
    var hrv: Double!
    {
        get
        {
            return 0.0
        }
    }

}

class Meditation
{
    var duration: TimeInterval!
    {
        get { return Date().timeIntervalSinceNow }
    }
    var hrv: Double!
    {
        get { return 0.0 }
    }
    
    var start : Date!
    {
        get { return Date() }
    }
    
}

