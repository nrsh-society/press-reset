//
//  SetGoalInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Anton Pavlov on 31/01/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import WatchKit

class SetGoalInterfaceController: WKInterfaceController {
    
    @IBOutlet var mainGroup: WKInterfaceGroup!
    @IBOutlet var doneButton: WKInterfaceButton!
    @IBOutlet var topLabel: WKInterfaceLabel!
    @IBOutlet var minusGroup: WKInterfaceGroup!{
        didSet {
            if WKInterfaceDevice.AW42 {
                minusGroup.setHeight(40)
                minusGroup.setWidth(40)
                minusGroup.setCornerRadius(20)
            } else if WKInterfaceDevice.AW38 {
                minusGroup.setHeight(28)
                minusGroup.setWidth(28)
                minusGroup.setCornerRadius(14)
            } else if WKInterfaceDevice.AW40 {
                minusGroup.setHeight(30)
                minusGroup.setWidth(30)
                minusGroup.setCornerRadius(15)
            }
        }
    }
    @IBOutlet var plusGroup: WKInterfaceGroup!{
        didSet {
            if WKInterfaceDevice.AW42 {
                plusGroup.setHeight(40)
                plusGroup.setWidth(40)
                plusGroup.setCornerRadius(20)
            } else if WKInterfaceDevice.AW38 {
                plusGroup.setHeight(28)
                plusGroup.setWidth(28)
                plusGroup.setCornerRadius(14)
            } else if WKInterfaceDevice.AW40 {
                plusGroup.setHeight(30)
                plusGroup.setWidth(30)
                plusGroup.setCornerRadius(15)
            }
        }
    }
    @IBOutlet var timeLabel: WKInterfaceLabel!
    
    var session: Session?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let session = context as? Session {
            self.session = session
            
            doneButton.setHidden(false)
            topLabel.setText("Set a daily mindfulness goal to get timers + reminders on progress")
           
            if WKInterfaceDevice.AW38 || WKInterfaceDevice.AW40 {
                mainGroup.sizeToFitHeight()
            }
        }
    }
    
    override func willActivate() {
        super.willActivate()
        
        updateTime()
    }
    
    func updateTime() {
        let mins = String(SettingsWatch.dailyMediationGoal)
        timeLabel.setText(mins)
    }
    
    @IBAction func plusAction() {
        SettingsWatch.dailyMediationGoal += 1
        updateTime()
    }
    
    @IBAction func minusAction() {
        if SettingsWatch.dailyMediationGoal > 5 {
            SettingsWatch.dailyMediationGoal -= 1
            updateTime()
        }
    }
    
    @IBAction func doneAction() {
        if let session = session {
            WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "AppInterfaceController", context: session as AnyObject), (name: "OptionsInterfaceController", context: session as AnyObject)])
        }
    }
}
