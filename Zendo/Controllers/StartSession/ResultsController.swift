//
//  ResultsController.swift
//  Zendo
//
//  Created by Boris Sedov on 17.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//
    

import UIKit
import HealthKit
import Mixpanel
import Charts

class ResultsController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    var hrvData : LineChartData? = nil
    var close: (()->())?
    
//    var start: Date!
//    var end: Date!
    
    var start = Date().addingTimeInterval(-60*30)
    var end = Date().addingTimeInterval(-60*20)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

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
        
        initHRVData()
    }
    
    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        close?()
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
    
    func populateCharts(_ cell: ResultTableCell) {
        
        cell.isHiddenHRV = true
        
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
                                                
                        cell.hrvChart.xAxis.setLabelCount(12, force: true)
                        
                        let xaxis = XAxis()
                        xaxis.valueFormatter = MMChartFormatterHour()
                        
                        cell.hrvChart.xAxis.valueFormatter = xaxis.valueFormatter
                        
                        cell.hrvChart.data!.highlightEnabled = true
                        self.hrvData?.notifyDataChanged()
                        cell.hrvChart.notifyDataSetChanged()
                        cell.hrvChart.fitScreen()
                        cell.isHiddenHRV = false
                        
                    }
            }
        }
        
        ZBFHealthKit.getHRVSamples(start: start, end: end, currentInterval: .minute, handler: handler)
    }
    
    func getCommunityDataEntry(key: String, interval: Double, scale: Double) -> ChartDataEntry {
           var value = CommunityDataLoader.get(measure: key, at: interval)
           value = value * scale
           
           return ChartDataEntry(x: interval, y: value.rounded())
       }
    
    func populateHRV(_ cell: ResultTableCell) {
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

}

extension ResultsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeaderOverviewTableViewCell.reuseIdentifierCell) as! HeaderOverviewTableViewCell
        cell.backgroundColor = UIColor.zenDarkGreen
        cell.dateTimeTitle.text = Date().toZendoHeaderDayTimeString
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ResultTableCell.reuseIdentifierCell, for: indexPath) as! ResultTableCell
        
        populateHRV(cell)
        populateCharts(cell)
        
        return cell
    }
    
}


extension ResultsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    
}

// MARK: - Static

extension ResultsController {
    
    static func loadFromStoryboard() -> ResultsController {
        return UIStoryboard(name: "StartSession", bundle: nil).instantiateViewController(withIdentifier: "ResultsController") as! ResultsController
    }
    
}
