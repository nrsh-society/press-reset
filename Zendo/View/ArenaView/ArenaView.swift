//
//  ArenaView.swift
//  Zendo
//
//  Created by Anton Pavlov on 01/03/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import Charts

class ArenaView: UIView {
    
    @IBOutlet weak var hudView: UIView!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var hrv: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var hrvImage: UIImageView! {
        didSet {
//            hrvImage.image = UIImage(named: "hrvTemp")!.withRenderingMode(.alwaysTemplate)
//            hrvImage.tintColor = UIColor.white

        }
    }
    @IBOutlet weak var timeImage: UIImageView! {
        didSet {
//            timeImage.image = UIImage(named: "timeTemp")?.withRenderingMode(.alwaysTemplate)
//            timeImage.tintColor = UIColor.white
        }
    }
    
    @IBOutlet weak var hrvLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var lineChartView: LineChartView! {
        didSet {
            
            lineChartView.clipsToBounds = true
            lineChartView.layer.cornerRadius = 20.0
            
            let zendoFont = UIFont.zendo(font: .antennaRegular, size: 10.0)
            
            lineChartView.noDataText = ""
            lineChartView.autoScaleMinMaxEnabled = true
            lineChartView.chartDescription?.enabled = false
            lineChartView.drawGridBackgroundEnabled = false
            lineChartView.pinchZoomEnabled = false
            
            let xAxis = lineChartView.xAxis
            xAxis.drawGridLinesEnabled = false
            xAxis.drawAxisLineEnabled = false
            xAxis.labelPosition = .bottom
            xAxis.labelTextColor = UIColor.zenGray
            xAxis.labelFont = zendoFont
            
            let rightAxis = lineChartView.rightAxis
            rightAxis.drawAxisLineEnabled = false
            rightAxis.drawGridLinesEnabled = false
            rightAxis.labelTextColor = UIColor.white
            rightAxis.labelPosition = .insideChart
            rightAxis.labelFont = zendoFont
            rightAxis.yOffset = -12.0
            rightAxis.drawTopYLabelEntryEnabled = false
            rightAxis.labelCount = 5
            
            let leftAxis = lineChartView.leftAxis
            leftAxis.drawAxisLineEnabled = false
            leftAxis.drawGridLinesEnabled = false
            leftAxis.drawLabelsEnabled = false
            
            //lineChartView.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 0)
            lineChartView.highlightPerTapEnabled = false
            lineChartView.highlightPerDragEnabled = false
            lineChartView.doubleTapToZoomEnabled = false
            
            lineChartView.legend.enabled = false
            
            lineChartView.highlightPerTapEnabled = false
            
            lineChartView.highlightValues([])
            lineChartView.xAxis.drawGridLinesEnabled = false
            lineChartView.xAxis.drawAxisLineEnabled = false
            lineChartView.rightAxis.drawAxisLineEnabled = false
            lineChartView.leftAxis.drawAxisLineEnabled = false
            
            lineChartView.drawGridBackgroundEnabled = false
            lineChartView.chartDescription?.enabled = false
            lineChartView.autoScaleMinMaxEnabled = true
            lineChartView.noDataText = ""
            
            initChartData()
            setChart([])
        }
    }
    
    var chartData: LineChartData? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
    }
    
    func initChartData() {
        let dataset = LineChartDataSet(values: [ChartDataEntry](), label: "")
        dataset.mode = .horizontalBezier
        dataset.drawValuesEnabled = false
        dataset.setColor(UIColor.white)
        dataset.lineWidth = 1.5
        dataset.label = "bpm"
        dataset.fillAlpha = 0.3
        dataset.fillColor = UIColor.white
        dataset.drawFilledEnabled = true
        
        dataset.drawCirclesEnabled = false
        
        self.chartData = LineChartData(dataSets: [dataset])
    }
    
    func setChart(_ hrv: [(key: String, value: Int)]) {
        
        let dataset = chartData?.getDataSetByIndex(0)!
        
        dataset?.clear()
        
        if lineChartView.data == nil {
            lineChartView.data = chartData
        }
        
        for entry in hrv {
            if entry.value > Int(0.0) {
                if let key = Double(entry.key) {
                    _ = dataset?.addEntry(ChartDataEntry(x: key, y: Double(entry.value)))
                }
            }
        }
        
        let formato = MMChartHRVFormatter()
        
        let xaxis = XAxis()
        xaxis.valueFormatter = formato
        
        
        lineChartView.xAxis.valueFormatter = xaxis.valueFormatter
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.axisMaxLabels = 5
        self.chartData?.notifyDataChanged()
        lineChartView.notifyDataSetChanged()
        lineChartView.fitScreen()
        
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 20.0
        backgroundColor = UIColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor(red:0, green:0, blue:0, alpha:0.5).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 20
    }
    
}
