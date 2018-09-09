//
//  BluetoothManager.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 9/3/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import CoreBluetooth

class BluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
    let BLE_Heart_Rate_Service_CBUUID = CBUUID(string: "0x180D")
    let BLE_Heart_Rate_Measurement_Characteristic_CBUUID = CBUUID(string: "0x2A37")
    let BLE_Body_Sensor_Location_Characteristic_CBUUID = CBUUID(string: "0x2A38")
    
    var queue : DispatchQueue? = DispatchQueue(label: "tools.sunyata.zendo")
    var peripheralHeartRateMonitor: CBPeripheral?
    var manager : CBCentralManager?
    
    public var isRunning : Bool = false
    public var statusDelegate : BluetoothManagerStatusDelegate?
    public var dataDelegate : BluetoothManagerDataDelegate?
    public var status : String = ""
    
    override init()
    {
        super.init()
    }
    
    func start()
    {
        if(!isRunning)
        {
            isRunning = true
            manager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "tools.sunyata.zendo"))
        }
    }
    
    func isConnected() -> Bool
    {
        return peripheralHeartRateMonitor != nil
    }
    
    func end()
    {
        if(isRunning)
        {
            self.updateStatus("")
            
            if let manager = self.manager
            {
                if(manager.isScanning)
                {
                    manager.stopScan()
                }
                if let peripheral = peripheralHeartRateMonitor
                {
                    manager.cancelPeripheralConnection(peripheral)
                }
                
                self.manager = nil
            }
            
            self.isRunning = false
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        var status = ""
        
        switch central.state
        {
            
            case .unknown:
                status = "BT Unknown"
            
            case .resetting:
                status = "BT Resetting"
            
            case .unsupported:
                status = "BT Unsupported"
            
            case .unauthorized:
                status = "BT Unauthorized"
            
            case .poweredOff:
                status = "Bluetooth Off"
                self.peripheralHeartRateMonitor = nil
            
            case .poweredOn:
                status = "Scanning"
                manager?.scanForPeripherals(withServices: [BLE_Heart_Rate_Service_CBUUID])
        }
        
        self.updateStatus(status)
    }
    
    func updateStatus(_ status: String)
    {
        self.status = status
        
        if let delegate = self.statusDelegate
        {
            delegate.statusUpdated(status)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        decodePeripheralState(peripheralState: peripheral.state)
        
        peripheralHeartRateMonitor = peripheral
        
        peripheralHeartRateMonitor?.delegate = self
        
        manager?.stopScan()
        
        manager?.connect(peripheralHeartRateMonitor!)
        
        if let name = peripheral.name
        {
            self.updateStatus(name)
        }
    }
    
    func decodePeripheralState(peripheralState: CBPeripheralState)
    {
        
        var status = ""
        
        switch peripheralState
        {
            
        case .disconnected:
            status = "Disconnected"
            
        case .connected:
            status = "Connected"
            
        case .connecting:
            status = "Connecting"
            
        case .disconnecting:
            status = "Disconnecting"
        }
        
        self.updateStatus(status)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        self.updateStatus("Disconnected")
        
        self.peripheralHeartRateMonitor = nil
        
        manager?.scanForPeripherals(withServices: [BLE_Heart_Rate_Service_CBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        statusDelegate?.statusUpdated(peripheral.name!)
        
        peripheralHeartRateMonitor?.discoverServices([BLE_Heart_Rate_Service_CBUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        for service in peripheral.services! {
            
            if service.uuid == BLE_Heart_Rate_Service_CBUUID
            {
                self.updateStatus(peripheral.name!)
                
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        for characteristic in service.characteristics! {
            
            if characteristic.uuid == BLE_Heart_Rate_Measurement_Characteristic_CBUUID
            {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if characteristic.uuid == BLE_Heart_Rate_Measurement_Characteristic_CBUUID
        {
            let rr = processHRCharacteristic(characteristic: characteristic)
            
            self.updateRR(rr)
        }
    }
    
    func updateRR(_ value : Int)
    {
        if let delegate = self.dataDelegate
        {
            delegate.rrIntervalUpdated(value)
        }
    }
    
    func processHRCharacteristic(characteristic: CBCharacteristic) -> Int
    {
        var retval: Int = 0
        
        let rxData = characteristic.value
        
        if let rxData = rxData
        {
            
            var flags = UInt8()
            var bpm = UInt8()
            let bpmRange = NSRange.init(location: 1, length: 1)
            let rrByteCount = rxData.count - 2
            var rrArray = [UInt16](repeating: 0, count: rrByteCount)
            let rrRange = NSRange.init(location: 2, length: rrByteCount)
            (rxData as NSData).getBytes(&flags, length: 1)
            (rxData as NSData).getBytes(&bpm, range: bpmRange)
            (rxData as NSData).getBytes(&rrArray, range: rrRange)
            
            for rr in rrArray
            {
                if rr != 0
                {
                    retval = Int(rr)
                    print("rr", retval)
                }
            }
        }
        
        return retval
    }
}

protocol BluetoothManagerStatusDelegate
{
    func statusUpdated(_ status:String)
}

protocol BluetoothManagerDataDelegate
{
    func rrIntervalUpdated( _ rr : Int)
}
