//
//  ZensorWatch.swift
//
//  Created by Douglas Purdy on 1/24/20.
//  Copyright © 2020 Zendo Tools. All rights reserved.
//
import Parse
import HomeKit
import Foundation
import CoreBluetooth

public class Zensor : Identifiable, ObservableObject
{
    var batt : UInt8 = 0
    
    public var id : UUID
    public var name : String
    var startDate = Date()
    
    @Published public var hrv : String = "0.0"
    @Published public var hr : String = "0.0"
    @Published public var duration : String = "0"
    @Published public var progress : String = "true/0"
    @Published public var isMeditating : Bool = false
    @Published public var isInBreath : Bool = false
    @Published public var isOutBreath : Bool = false
    @Published public var level : Int = 0
    @Published public var samples = [Float]()
    
    init(id: UUID, name: String, hr: Float, batt: UInt8) {
        
        self.id = id
        self.name = name
        self.hr = hr.description
        self.batt = batt
    }
    
    func update(hr: Float) {
        
        self.samples.append(hr)
        
        self.hr = hr.rounded().description
         
        self.duration = self.getDuration().description
        
        self.isInBreath = self.getInBreath()
                   
        self.isOutBreath = self.getOutBreath()
        
        self.hrv = self.getHRV().description

        if (self.samples.count > 9 && self.samples.count % 10 == 0)
        {
            self.isMeditating = getMeditativeState()
            
            self.level = getLevel()
                        
            self.progress = self.getProgress()
            
            self.publish()
        }
    }
    
    func update(progress: String)
    {
        self.progress = progress
        self.publish()
    }
    
    
    func getInBreath() -> Bool
    {
        var retval = false
        
        if(self.samples.count > 9)
        {
            let lastSamples = Array(self.samples.suffix(3))
            
            if(lastSamples.count == 3)
            {
                //is the heartrate sloping up?
                retval = lastSamples[0] + lastSamples[1] < lastSamples[1] + lastSamples[2]
            }
        }
        
        return retval
    }
    
    func getOutBreath() -> Bool
    {
        var retval = false
        
        if(self.samples.count > 10)
        {
            let lastSamples = Array(self.samples.suffix(3))
            
            if(lastSamples.count == 3)
            {
                //is the heartrate sloping down?
                retval = lastSamples[2] + lastSamples[1] < lastSamples[1] + lastSamples[0]
            }
        }
        
        return retval
    }
    
    func getLevel() -> Int {
        
        var retval = 0
        
        if(self.isMeditating)
        {
            retval = self.level + 1
        }
        
        return retval
    }
    
    func getMeditativeState() -> Bool
    {
        var retval = false
        
        if (self.samples.count > 10)
        {
            let min = self.samples.suffix(10).min()
            let max = self.samples.suffix(10).max()
            
            let range = max! - min!
            
            if range > 3.0
            {
                retval = true
            }
            
        }
        
        return retval
    }
    
    func getDuration() -> Int
    {
        let startDate = self.startDate
        
        let seconds = abs(startDate.seconds(from: Date()))
        
        return seconds
    }
    
    func getProgress() -> String
    {
        progress = "\(self.isMeditating)/\(self.level)"
    
        return progress
    }
    
    func getUpdate() -> [String : String]
    {
        return ["duration": self.duration, "hr" : self.hr, "hrv" : self.hrv, "meditating": self.isMeditating.description , "level": self.level.description, "progress" : self.progress]
    }
    
    func getHRV() -> Float
    {
        return self.standardDeviation(self.samples)
    }
    
    func standardDeviation(_ arr : [Float]) -> Float
    {
        
        let rrIntervals = arr.map
        {
            (beat) -> Float in
            
            return 1000 / beat
        }
        
        let length = Float(rrIntervals.count)
        
        let avg = rrIntervals.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = rrIntervals.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    func publish()
    {
        /*
         
         convert from Firebase to Parse
         
        let database = Database.database().reference()
        let players = database.child("players")
        
        let name = self.name.replacingOccurrences(of: ".", with: "_")
        
        let key = players.child(name)
        
        key.setValue(self.getUpdate())
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
                
                return
            }
            
        }
         */
        
    }
    
    func reset()
    {
        /*
        
         convert from firebase to parse
         
        let database = Database.database().reference()
        
        let players = database.child("players")
        
        let name = self.name.replacingOccurrences(of: ".", with: "_")
        
        let key = players.child(name)
        
        key.removeValue()
         */
        
    }
}

open class Zensors : NSObject, CBCentralManagerDelegate, HMHomeManagerDelegate, ObservableObject {

    let centralQueue: DispatchQueue = DispatchQueue(label: "tools.sunyata.zendo", attributes: .concurrent)
    
    var centralManager: CBCentralManager!
     
    @Published public var current: [Zensor] = []
    
    let homeManager = HMHomeManager()
    
    var lightCharacteristic : HMCharacteristic? = nil
    
    var appleWatch : Zensor?
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            let raw_hrv = sample["sdnn"] as! String
            let double_hrv = Double(raw_hrv)!.rounded()
            let text_hrv = Int(double_hrv.rounded()).description
            
            let raw_hr = sample["heart"] as! String
            let double_hr = (Double(raw_hr)! * 60).rounded()
            let int_hr = Int(double_hr)
            let text_hr = int_hr.description
            
            if (double_hr  != 0)
            {
                DispatchQueue.main.async
                    {
                        if let watch  = self.appleWatch
                        {
                            watch.update(hr: Float(double_hr) )
                        }
                        else
                        {
                            self.appleWatch = Zensor(id: UUID() , name: SettingsWatch.email!, hr: Float(double_hr) , batt: 100)
                            self.current.append(self.appleWatch!)
                        }
                }
            }
        }
    }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? String
        {
            if let watch  = self.appleWatch
            {
                watch.update(progress: progress.description.lowercased())
            }
        }
    }

    override init()
    {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    
        homeManager.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.sample), name: .sample, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.progress), name: .progress, object: nil)
        
        /*NotificationCenter.default.addObserver(self,
                                               selector: #selector(startSession),
                                               name: .startSession,
                                               object: nil)
        
        //NotificationCenter.default.addObserver(self,
                                               selector: #selector(endSession),
                                               name: .endSession,
                                               object: nil)
 */
        
    }
    
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        
        guard let home = manager.homes.first else { return }
  
        let lights = home.accessories.filter { $0.category.categoryType == HMAccessoryCategoryTypeLightbulb }

        let lightCharacteristics = lights
        .flatMap { $0.services }
        .flatMap { $0.characteristics }
        .filter { $0.characteristicType == HMCharacteristicTypeBrightness }

        self.lightCharacteristic = lightCharacteristics.first!
        
    }
    
    func reset()
    {
        self.current.forEach {
            
            (zensor) in
            
            zensor.reset()
        }
        
        self.current.removeAll()
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        switch central.state
        {
        case .poweredOn:
            
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            
            print("Bluetooth status is POWERED OFF")
            
        case .unknown, .resetting, .unsupported, .unauthorized: break
            
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber)
    {
        
        var bytes=[UInt8](repeating:0, count:16)
        var hr_bytes=[UInt8](repeating:0, count:4)
        var batt_byte=[UInt8](repeating:0, count:1)
        
        if let payload: NSData = advertisementData["kCBAdvDataManufacturerData"] as? NSData
        {
            if let name = peripheral.name
            {
                if name.lowercased().contains("movesense")
                {
                    payload.getBytes(&bytes,length:15)
                    
                    var hr:Float = 0
                    var batt:UInt8 = 0
                    
                    for i in 7...10 {
                        hr_bytes[i-7]=bytes[i]
                    }
                    
                    batt_byte[0]=bytes[14]
                    
                    memcpy(&hr,&hr_bytes,4)
                    memcpy(&batt,&batt_byte,1)
                    
                    if (hr != 0)
                    {
                        DispatchQueue.main.async
                            {
                                if let zensor  = self.current.first(where: { $0.id == peripheral.identifier })
                                {
                                    zensor.update(hr: hr)
                                    
                                    if peripheral.name!.contains("502") {
                                        
                                        var brightness = 0.0
                                        
                                        if(zensor.isInBreath)
                                        {
                                            brightness = 100.0
                                        }
                                        
                                        self.lightCharacteristic?.writeValue(NSNumber(value: Double(brightness)), completionHandler: { if let error = $0 { print("Failed: \(error)") } })
                                    }
                                }
                                else
                                {
                                    let zensor = Zensor(id: peripheral.identifier , name: peripheral.name ?? "unknown", hr: hr, batt: batt)
                                    self.current.append(zensor)
                                }
                        }
                    }
                }
            }
        }
    }
}
