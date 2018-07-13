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

class OverviewController : UIViewController
{
    @IBOutlet weak var mmChart: Chart!
    @IBOutlet weak var hrvChart: Chart!
    @IBOutlet weak var bpmChart: Chart!
    
    var mmData : Dictionary<Double, Double> = [:]
    
    func stringForValue(_ value: Double) -> String {
        
        let date = Date(timeIntervalSince1970: value)
        
        let dateFormatter = DateFormatter();
        
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
        
        let localDate = dateFormatter.string(from: date)
        
        return localDate.description
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        ZBFHealthKit.requestHealthAuth(handler:
            {
                (success,error) in
                
                DispatchQueue.main.async()
                    {
                        if(success)
                        {
                            self.populateMMChart()
                            self.populateHRVChart()
                            self.populateBPMChart()
                            
                            self.mmChart.topInset = 33.0
                            self.mmChart.maxX = 3
                            self.bpmChart.topInset = 33.0
                            self.bpmChart.maxX = 3
                            self.hrvChart.topInset = 33.0
                            self.hrvChart.maxX = 3
                            
                            self.mmChart.highlightLineWidth = 0.0
                            self.bpmChart.highlightLineWidth = 0.0
                            self.hrvChart.highlightLineWidth = 0.0
                            
                        }
                        else
                        {
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
    
    func populateMMChart()
    {
        ZBFHealthKit.getMindfulMinutes(daysPrior: 7)
        {
            samples, error in
            
            if (samples.count > 0)
            {
                let start = samples.first?.startDate
                
                let end = samples.last?.endDate
                
                let calendar = Calendar.current
                
                let components = calendar.dateComponents( [.day], from: start!, to: end!)
                
                let days = components.day!
                
                self.mmData = Dictionary<Double, Double>(minimumCapacity: days)
                
                samples.forEach(
                    {
                        (sample) in
                        
                        let keyDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: sample.startDate)!
                        
                        let startDate = sample.startDate
                        
                        let endDate = sample.endDate
                        
                        let delta = DateInterval(start: startDate, end: endDate)
                        
                        let key = keyDate.timeIntervalSince1970
                        
                        if let existingValue = self.mmData[key]
                        {
                            self.mmData[key] = existingValue + delta.duration
                        }
                        else
                        {
                            self.mmData[key] = delta.duration
                        }
                        
                })
                
                var mmDataEntries : [(x: Double, y: Double)] = [(x:Double, y: Double)]()
                
                self.mmData.sorted(by: <).forEach(
                    {
                        
                        (key, value) in
                        
                        if (value > 0.0)
                        {
                            mmDataEntries.append((x: key, y: value / 60))
                        }
                        
                        print((x: key, y: value))
                        
                })
                
                DispatchQueue.main.async()
                    {
                        
                        let mmDataSeries = ChartSeries(data: mmDataEntries)
                        
                        mmDataSeries.area = true
                        
                        mmDataSeries.colors = (
                            above: ChartColors.greenColor(),
                            below: ChartColors.yellowColor(),
                            zeroLevel: 30
                        )
                        
                        self.mmChart.add(mmDataSeries)
                        
                        self.mmChart.xLabelsFormatter  = { self.stringForValue($1) }
                        
                }
            }
            else
            {
                print(error.debugDescription)
            }
        }
    }
    
    func populateHRVChart()
    {
        var hrvDataEntries : [(x: Double, y: Double)] = [(x:Double, y: Double)]()
        
        ZBFHealthKit.getHRVSamples(daysPrior: 7) {
            
            (samples, error) in
            
            if let entries = samples
            {
                entries.sorted(by: <).forEach(
                    {
                        (entry) in
                        
                        if (entry.value > 0.0)
                        {
                            
                            hrvDataEntries.append((x: entry.key, y: entry.value))
                        }
                        print("populateHRVChart: \(entry)")
                        
                })
                
                DispatchQueue.main.async()
                {
                        let hrvDataSeries = ChartSeries(data: hrvDataEntries)
                        
                        hrvDataSeries.area = true
                        
                        hrvDataSeries.colors = (
                            above: ChartColors.greenColor(),
                            below: ChartColors.yellowColor(),
                            zeroLevel: 40
                        )
                        
                        self.hrvChart.add(hrvDataSeries)
                        
                        self.hrvChart.xLabelsFormatter  = { self.stringForValue($1) }
                        
                }
            }
            else
            {
                print(error.debugDescription)
            }
            
        }
    }
    
    func populateBPMChart()
    {
        var bpmDataEntries : [(x: Double, y: Double)] = [(x:Double, y: Double)]()
        
        ZBFHealthKit.getBPMSamples(daysPrior: 7) {
            
            (samples, error) in
            
            if let entries = samples
            {
                entries.sorted(by: <).forEach(
                    {
                        (entry) in
                        
                        if (entry.value > 0.0)
                        {
                            
                            bpmDataEntries.append((x: entry.key, y: entry.value))
                        }
                        
                        print("populateBPMChart: \(entry)")
                })
                
                DispatchQueue.main.async()
                    {
                        let bpmDataSeries = ChartSeries(data: bpmDataEntries)
                        
                        bpmDataSeries.area = true
                        
                        bpmDataSeries.colors = (
                            above: ChartColors.redColor(),
                            below: ChartColors.greenColor(),
                            zeroLevel: 60
                        )
                        
                        self.bpmChart.add(bpmDataSeries)
                        
                        self.bpmChart.xLabelsFormatter  = { self.stringForValue($1) }
                        
                }
            }
            else
            {
                print(error.debugDescription)
            }
            
        }
    }
    
    @IBAction func newSession(_ sender: Any) {
        
        ZBFHealthKit.getPermissions()
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        let store = HKHealthStore()
            
        store.startWatchApp(with: configuration)
        {
            (success, error) in
            
            guard success else
            {
                print (error.debugDescription)
                return
            }
        }
        
        Mixpanel.mainInstance().time(event: "new_session")
        
        let alert = UIAlertController(title: "Starting Watch App",
                                      message: "Deep Press + Exit when complete.", preferredStyle: .actionSheet)
        
        let ok = UIAlertAction(title: "Done", style: .default)
        {
            action in
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) )
            {
                Mixpanel.mainInstance().track(event: "new_session")
            }
            
        }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion:
        {
                
        })
    }
}
