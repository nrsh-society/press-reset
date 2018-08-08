//
//  OverviewTableViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Charts

class HeaderOverviewTableViewCell: UITableViewCell {
    @IBOutlet weak var dateTimeTitle: UILabel!
    @IBOutlet var buttons: [UIButton]!
    @IBAction func actionButton(_ sender: UIButton) {
        action?(sender.tag)
    }
    
    var action: ((_ tag: Int)->())?
}

class OverviewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var durationView: ZenInfoView! {
        didSet {
            durationView.zenInfoViewType = .totalMins
        }
    }
    @IBOutlet weak var hrvView: ZenInfoView! {
        didSet {
            hrvView.zenInfoViewType = .hrvAverage
        }
    }
    @IBOutlet weak var mmChart: LineChartView!
    @IBOutlet weak var hrvChart: LineChartView!
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
        
    }

}
