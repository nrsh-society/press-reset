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
        
    }
    
    override func didDeactivate()
    {
        super.didDeactivate()
        
        Mixpanel.sharedInstance()?.track("watch_options")
    }
    
}
