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
    
    @IBAction func queryChanged(_ sender: Any) {
        
        let segment = sender as! UISegmentedControl
        
        let idx = segment.selectedSegmentIndex
        
        print(idx)
        
        self.mmChart.removeAllSeries()
        
    
         
        
        switch idx
        {
            case 0:
                populateHRVChart(.hour, 24)
                populateBPMChart(.hour, 24)
                break
            case 1:
                populateHRVChart(.day, 7)
                populateBPMChart(.day, 7)
                break
            case 2:
                populateHRVChart(.month, 1)
                populateBPMChart(.month, 1)
                break
            case 3:
                populateHRVChart(.year, 1)
                populateBPMChart(.year, 1)
                break
            default:
                break
        }
    }
    
    func stringForValue(_ value: Double, _ interval : Calendar.Component) -> String {
        
        let date = Date(timeIntervalSince1970: value)
        
        let dateFormatter = DateFormatter();
        
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        
        switch interval
        {
        case .hour:
            dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
            break
            
        case .day:
            dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
            break
            
        case .month:
            dateFormatter.setLocalizedDateFormatFromTemplate("MM-dd")
            break
            
        case .year:
            dateFormatter.setLocalizedDateFormatFromTemplate("MM")
            break
            
        default:
            dateFormatter.setLocalizedDateFormatFromTemplate("MM")
            break
        }
        
        let localDate = dateFormatter.string(from: date)
        
        return localDate.description
        
    }
    
    func showController(_ named: String) {
        
        Mixpanel.mainInstance().time(event: named + "_enter")
        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: named)
        
        present(controller, animated: true, completion: {
            Mixpanel.mainInstance().track(event: named + "_exit")
        });
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        
        if defaults.string(forKey: "runonce") == nil
        {
            defaults.set(true, forKey: "runonce")
            
            self.showController("welcome-controller")
            
        }
        
        ZBFHealthKit.requestHealthAuth(handler:
            {
                (success, error) in
                
                DispatchQueue.main.async()
                    {
                        if(success)
                        {
                            self.populateHRVChart(.hour, 24)
                            self.populateBPMChart(.hour, 24)
                            
                            self.mmChart.topInset = 33.0
                            self.bpmChart.topInset = 33.0
                            self.hrvChart.topInset = 33.0
                            
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
    
    func populateHRVChart(_ interval: Calendar.Component, _ range: Int)
    {
        var hrvDataEntries  = [(x:Double, y: Double)]()
        var communityDataEntries = [(x:Double, y: Double)]()
        
        self.hrvChart.removeAllSeries()
        
        let handler : ZBFHealthKit.SamplesHandler = {
            
            (samples, error) in
            
            if let samples = samples
            {
                let sorted = samples.sorted(by: <)
               
                sorted.forEach(
                    {
                        (entry) in

                            hrvDataEntries.append((x: entry.key, y: entry.value))
                        
                            let value = CommunityDataLoader.get(measure: "sdnn", at: entry.key)
                        
                            communityDataEntries.append((x: entry.key, y: value))
                        
                            print("populateHRVChart: \(entry)")
                })
                
                DispatchQueue.main.async()
                    {
                        let hrvDataSeries = ChartSeries(data: hrvDataEntries)
                        let communityDataSeries = ChartSeries(data: communityDataEntries)
                        
                        self.hrvChart.add([hrvDataSeries, communityDataSeries])
                        
                        self.hrvChart.xLabelsFormatter =
                        {
                            
                            self.stringForValue($1, interval)
                            
                        }
                }
                
                let keys = samples.keys.sorted()
                
                var entries = [(x:Double, y: Double)]()
                
                for (i, key) in keys.enumerated()
                {
                    let start = Date(timeIntervalSince1970: key)
                    
                    let idx = i + 1
                    let last = (i == keys.count - 1)
                    
                    let end = last ? Date() : Date(timeIntervalSince1970: keys[idx])
                
                    ZBFHealthKit.getMindfulMinutes(start: start, end: end)
                    {
                        samples, error in
                        
                        if let samples = samples
                        {
                            samples.sorted(by: <).forEach(
                                {
                                    (entry) in
                                    
                                    entries.append((x: entry.key, y: entry.value / 60))
                                    
                                    print("populateMMChart: \(entry)")
                                    
                            })
                            
                                DispatchQueue.main.async()
                                    {
                                        
                                        if (self.mmChart.series.count == 1)
                                        {
                                            self.mmChart.removeSeriesAt(0)
                                        }
                                        
                                        entries.sort(by:<)
                                        
                                        let mmDataSeries = ChartSeries(data: entries)
                                        
                                        self.mmChart.add(mmDataSeries)
                                            
                                        self.mmChart.xLabelsFormatter  = {
                                                
                                            self.stringForValue($1, interval)
                                                
                                        }
                                        
                                }
                            
                            }
                        else
                        {
                            print(error.debugDescription)
                        }
                    }
                }
            }
            else
            {
                print(error.debugDescription)
            }
            
        }
        
        ZBFHealthKit.getHRVSamples(interval: interval, value: range, handler: handler)
        
    }
    
    func populateBPMChart(_ interval: Calendar.Component, _ range: Int)
    {
        var bpmDataEntries : [(x: Double, y: Double)] = [(x:Double, y: Double)]()
        
        self.bpmChart.removeAllSeries()
        
        ZBFHealthKit.getBPMSamples(interval: interval, value: range) {
            
            (samples, error) in
            
            if let entries = samples
            {
                entries.sorted(by: <).forEach(
                    {
                        (entry) in
                        
                        bpmDataEntries.append((x: entry.key, y: entry.value))
                    
                        print("populateBPMChart: \(entry)")
                })
                
                DispatchQueue.main.async()
                    {
                        let bpmDataSeries = ChartSeries(data: bpmDataEntries)
                        
                        self.bpmChart.add(bpmDataSeries)
                        
                        self.bpmChart.xLabelsFormatter =
                        {
                            
                            self.stringForValue($1, interval)
                            
                        }
                }
            }
            else
            {
                print(error.debugDescription)
            }
            
        }
    }
    
    //#todo(debt): factor this into the zbfmodel + ui across controllers
    @IBAction func newSession(_ sender: Any) {
        
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
