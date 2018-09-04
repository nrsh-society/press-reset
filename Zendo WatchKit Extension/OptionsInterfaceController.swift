//
//  OptionsInterfaceController.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 5/3/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import Foundation

class OptionsInterfaceController : WKInterfaceController, BluetoothManagerStatusDelegate
{
    
    @IBOutlet var bluetoothStatus: WKInterfaceLabel!
    @IBOutlet var hapticSetting: WKInterfaceSlider!
    @IBOutlet var bluetoothToogle: WKInterfaceSwitch!
    
    @IBAction func KyosakChanged(_ value: Float)
    {
        Session.options.hapticStrength = Int(value.rounded())
    }
    
    @IBAction func bluetoothChanged(_ value: Bool)
    {
        if(value)
        {
            Session.bluetoothManager = BluetoothManager()
            Session.bluetoothManager?.statusDelegate = self
            Session.bluetoothManager?.start()
        }
        else
        {
            Session.bluetoothManager?.end()
            bluetoothStatus.setText("")
        }
    }
    
    func statusUpdated(_ status: String)
    {
        DispatchQueue.main.sync
        {
            bluetoothStatus.setText(status)
        }
    }
    
    override func willActivate()
    {
        super.willActivate()
        
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
    }
    
}
