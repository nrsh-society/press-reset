//
//  OverviewTableViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 07/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Charts
import NVActivityIndicatorView


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
    @IBOutlet weak var mmDots: NVActivityIndicatorView!
    @IBOutlet weak var mmChart: LineChartView!
    @IBOutlet weak var hrvDots: NVActivityIndicatorView!
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
    
    var isHiddenHRV: Bool! {
        didSet {
            if oldValue != isHiddenHRV {
                isHiddenHRV ? hrvDots.startAnimating() : hrvDots.stopAnimating()
                hrvDots.isHidden = !isHiddenHRV
                hrvChart.isHidden = isHiddenHRV
            }
        }
    }
    
    var isHiddenMM: Bool! {
        didSet {
            if oldValue != isHiddenMM {
                isHiddenMM ? mmDots.startAnimating() : mmDots.stopAnimating()
                mmDots.isHidden = !isHiddenMM
                mmChart.isHidden = isHiddenMM
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let zendoFont = UIFont.zendo(font: .antennaRegular, size: 10.0)
        let arrayLineChart = [mmChart, hrvChart]
        
        for (index, lineChart) in arrayLineChart.enumerated() {
            lineChart?.noDataText = ""
            lineChart?.autoScaleMinMaxEnabled = true
            lineChart?.chartDescription.enabled = false
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
            
            lineChart?.setViewPortOffsets(left: 10, top: 10, right: 10, bottom: 45)
            lineChart?.highlightPerTapEnabled = false
            lineChart?.highlightPerDragEnabled = false
            lineChart?.doubleTapToZoomEnabled = false
            
            lineChart?.legend.textColor = UIColor(red: 0.05, green:0.2, blue: 0.15, alpha: 1)
            lineChart?.legend.font = UIFont.zendo(font: .antennaRegular, size: 10.0)
            lineChart?.legend.form = .circle
            
            lineChart?.highlightPerTapEnabled = true
            
            let marker = BalloonMarker(color: UIColor.zenDarkGreen,
                                       font: UIFont.zendo(font: .antennaRegular, size: 12),
                                       textColor: .white,
                                       insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                       chartType: index == 0 ? .mm : .hrv)
            marker.chartView = lineChart
            marker.minimumSize = CGSize(width: 80, height: 40)
            lineChart?.marker = marker
        }
        
    }

}
