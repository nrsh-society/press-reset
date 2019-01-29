//
//  OptionsInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 5/3/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import UIKit
import Mixpanel

class OptionsInterfaceController : WKInterfaceController, BluetoothManagerStatusDelegate
{
    
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
    @IBOutlet var bluetoothStatus: WKInterfaceLabel!
    @IBOutlet var hapticSetting: WKInterfaceSlider!
    @IBOutlet var bluetoothToogle: WKInterfaceSwitch!
    
    @IBAction func KyosakChanged(_ value: Float)
    {
        Mixpanel.sharedInstance()?.track("watch_options_haptic", properties: ["value": value])
        
        Session.options.hapticStrength = Int(value)
    }
    
    @IBAction func bluetoothChanged(_ value: Bool)
    {
        Mixpanel.sharedInstance()?.track("watch_options_bluetooth", properties: ["value": value])
        
        if(value)
        {
            Session.bluetoothManager = BluetoothManager()
            Session.bluetoothManager?.statusDelegate = self
            Session.bluetoothManager?.start()
        }
        else
        {
            Session.bluetoothManager?.end()
            Session.bluetoothManager = nil
            bluetoothStatus.setText("")
        }
    }
    
    func statusUpdated(_ status: String)
    {
        DispatchQueue.main.async
        {
            self.bluetoothStatus.setText(status)
        }
    }
    
    @IBAction func plusAction() {
        SettingsWatch.dailyMediationGoal += 1
        updateTime()
    }
    
    @IBAction func minusAction() {
        SettingsWatch.dailyMediationGoal -= 1
        updateTime()
    }
    
    override func willActivate()
    {
        super.willActivate()
        
        Mixpanel.sharedInstance()?.timeEvent("watch_options")
        
        if let bluetooth = Session.bluetoothManager
        {   self.bluetoothToogle.setOn(bluetooth.isRunning)
            Session.bluetoothManager?.statusDelegate = self
            bluetoothStatus.setText(bluetooth.status)
        }
        
        self.hapticSetting.setValue(Float(Session.options.hapticStrength))
        
        updateTime()
    }
    
    func updateTime() {
        let mins = String(SettingsWatch.dailyMediationGoal)
        timeLabel.setText(mins)
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_options")
    }
    
}
