//
//  SummaryInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 27/09/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import WatchKit
import HealthKit
import Mixpanel


class SummaryInterfaceController: WKInterfaceController {
    
    @IBOutlet var totalTime: WKInterfaceTimer!
    @IBOutlet var hrv: WKInterfaceLabel!
    @IBOutlet var bpm: WKInterfaceLabel!
    @IBOutlet var bpmRange: WKInterfaceLabel!
    
    var session: Session!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
       Mixpanel.sharedInstance()?.timeEvent("watch_summary")
        
        if  let array = context as? [String: Any],
            let session = array["session"] as? Session,
            let workout = array["workout"] as? HKWorkout
        {
            self.session = session;
            
            
            totalTime.setDate(session.startDate!)
            
            /*
            ZBFHealthKit.getHRVAverage(workout) { results, error in
                DispatchQueue.main.async() {
                    if let value = results?.first?.value, value > 0 {
                        self.hrv.setText(Int(value.rounded()).description + "ms")
                    } else {
                        self.hrv.setText("--")
                    }
                }
            }*/
            
            if session.heartSDNN > 0 {
                self.hrv.setText(Int(session.heartSDNN.rounded()).description + "ms")
            } else {
                self.hrv.setText("--")
            }
            
            if let metadata = workout.metadata {
                let heartArray = (metadata[MetadataType.heart.rawValue] as! String).components(separatedBy: "/")
                
                if !heartArray.isEmpty {
                    
                    var sum = 0.0
                    var max = (Double(heartArray[0]) ?? 0.0) * 60.0
                    var min = (Double(heartArray[0]) ?? 0.0) * 60.0
                    
                    for heart in heartArray {
                        if let valueDouble = Double(heart), valueDouble > 0.0 {
                            let value = valueDouble * 60.0
                            sum += value
                            
                            if value > max {
                                max = value
                            }
                            
                            if value < min {
                                min = value
                            }
                        }
                    }
                    
                    bpm.setText((Int(sum.rounded()) / heartArray.count).description + " bpm")
                    bpmRange.setText(Int(min.rounded()).description + " - " + Int(max.rounded()).description + " bpm")
                }
            }
            
        }
        
    }
    
    @IBAction func onDonePress() {
       Mixpanel.sharedInstance()?.track("watch_summary")
        
        //todo: need to move the save here or after this view unloads
        
        if SettingsWatch.isFirstSession {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: session as AnyObject), (name: "OptionsInterfaceController", context: session as AnyObject)])
        } else {
            SettingsWatch.isFirstSession = true
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SetGoalInterfaceController", context: session as AnyObject)])
        }
        
    }
    
    
    @IBAction func onHRVSwitchChanged(_ value: Bool)
    {
        //I promise that if you have written Smalltalk code, this will make sense.
        Session.options.saveHRVSamples = value
    }
    

}
