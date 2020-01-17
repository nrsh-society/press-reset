//
//  StartSessionController.swift
//  Zendo
//
//  Created by Boris Sedov on 10.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit
import WatchConnectivity
import CoreBluetooth
import HealthKit
import Mixpanel
import Hero


class StartSessionController: UIViewController {
    
    // MARK: - Outlet
    
    @IBOutlet weak var timeTopLabel: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet var spacesButton: [NSLayoutConstraint]!
    @IBOutlet weak var startButton: UIButton! {
        didSet {
            startButton.layer.cornerRadius = startButton.frame.height / 2.0
            startButton.layer.borderColor = UIColor.white.cgColor
            startButton.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var arenaView: ArenaView! {
        didSet {
            arenaView.isHidden = true
            arenaView.alpha = 1.0
            arenaView.hrv.text = "--"
            arenaView.time.text = "--"
        }
    }
    
    // MARK: - Let
    
    let startingSessions = StartSessionView()
    let healthStore = ZBFHealthKit.healthStore
    
    // MARK: - Var
    
    private var uuid_to_movesense_cache = [String: String]() //STORED AS UUID:MOVESENSEID
    private var movesense_to_uuid_cache = [String: String]() //STORED AS MOVESENSEID:UUID
    private var movesense_to_data_cache = [String: Double]()
    private var heartRateSamples = [Double]()
    //    private var movesense_to_data_cache = [String: (Float, String)]()
    
    private var centralManager: CBCentralManager!
    
    var chartHR = [String: Int]()
    
    var idHero = ""
    
    var listDevices = [DeviceLE]()
    
    var timer: Timer?
    var movesenseIsStart = false
    var heartSDNN = 0.0
    var metadataWork = [String: Any]()
    var start: Date?
    var end: Date?
    
    
}

// MARK: - LifeCycle

extension StartSessionController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStartingSessions()
        setCentralManager()
        setupWatchNotifications()
        
    }
    
}

// MARK: - CoreBluetooth

extension StartSessionController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            
            print("Bluetooth status is POWERED OFF")
            
        case .unknown, .resetting, .unsupported, .unauthorized: break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        //        guard let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID], let _ = uuids.first?.uuidString else { return }
        //        let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as! [CBUUID]
        
        if uuid_to_movesense_cache[peripheral.identifier.uuidString] != nil {
            
            var bytes=[UInt8](repeating:0, count:16)
            var hr_bytes=[UInt8](repeating:0, count:4)
            var batt_byte=[UInt8](repeating:0, count:1)
            let payload: NSData = advertisementData["kCBAdvDataManufacturerData"] as! NSData
            payload.getBytes(&bytes,length:15)
            
            var hr:Float = 0
            var batt:UInt8 = 0
            //            var batt_level = ""
            for i in 7...10 {
                hr_bytes[i-7]=bytes[i]
            }
            
            batt_byte[0]=bytes[14]
            memcpy(&hr,&hr_bytes,4)
            memcpy(&batt,&batt_byte,1)
            //            if batt == 1 {
            //                batt_level="Battery Full"
            //            } else {
            //                batt_level="Battery Low"
            //            }
            
            if let key = uuid_to_movesense_cache[peripheral.identifier.uuidString] {
                movesense_to_data_cache[key] = Double(hr)
                if movesenseIsStart {
                    sampleMovesense()
                }
            }
            
        } else if let name = Settings.nameMovesense { //We have not seen this UUID before
            if let movesense_id = advertisementData["kCBAdvDataLocalName"] as? String, movesense_id == name { //We received Movesense id
                
                if movesense_to_uuid_cache[movesense_id] == nil {
                    //Only add a new entry in the tables if the movesense id has never been seen before
                    uuid_to_movesense_cache[peripheral.identifier.uuidString] = movesense_id
                    movesense_to_uuid_cache[movesense_id] = peripheral.identifier.uuidString
                    
                    var isSelect = true
                    
                    if listDevices.isEmpty {
                        
                        for device in listDevices {
                            if device.type == .movesense {
                                isSelect = false
                                break
                            }
                        }
                        
                    } else {
                        isSelect = false
                    }
                    
                    let device = DeviceLE(type: .movesense, movesenseName: movesense_id, isSelect: isSelect)
                    listDevices.append(device)
                    
                } else if let old_uuid = movesense_to_uuid_cache[movesense_id] {
                    //Otherwise, the UUID for movesense device has changed and we need to update it in the tables.
                    uuid_to_movesense_cache[old_uuid] = movesense_id
                    movesense_to_uuid_cache[movesense_id] = peripheral.identifier.uuidString
                    
                }
                
            }
            
        }
        
        print("\(movesense_to_data_cache as AnyObject)")
        
    }
    
}

// MARK: - Method

extension StartSessionController {
    
    func showWatchSyncError(_ vc: WatchSyncError) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500) ) {
            UIApplication.topViewController()?.present(vc, animated: true)
        }
    }
    
    func rescan() {
        uuid_to_movesense_cache.removeAll()
        movesense_to_uuid_cache.removeAll()
        movesense_to_data_cache.removeAll()
        
        listDevices.removeAll()
        
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func setupWatchNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sample(notification:)),
                                               name: .sample,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startSession),
                                               name: .startSession,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(endSession),
                                               name: .endSession,
                                               object: nil)
    }
    
    func setCentralManager() {
        if let _ = Settings.nameMovesense {
            let centralQueue: DispatchQueue = DispatchQueue(label: "tools.sunyata.zendo", attributes: .concurrent)
            centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        }
    }
    
    func changeButtonSpace(isStart: Bool) {
        
        for (index, _) in spacesButton.enumerated() {
            spacesButton[index].constant = isStart ? 3.0 : 25.0
        }
        
    }
    
    func changeButton(isStart: Bool) {
        startButton.setTitle(isStart ? "End" : "Start", for: .normal)
    }
    
    func showTime() {
        
        var startDate: Date?
        
        if let date = Settings.connectedDate {
            startDate = date
        } else if let date = start {
            startDate = date
        }
        
        if let date = startDate, timer == nil {
            DispatchQueue.main.async {
                self.time.isHidden = false
                self.timeTopLabel.isHidden = false
                self.time.text = ""
                
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
                    
                    let nowDate = Date()
                    
                    let d = nowDate.timeIntervalSinceNow - date.timeIntervalSinceNow
                    
                    self.time.text = d.stringZendoTimeWatch
                    
                })
            }
        }
    }
    
    func hideTime() {
        timer?.invalidate()
        timer = nil
        time.isHidden = true
        timeTopLabel.isHidden = true
    }
    
    func setStartingSessions() {
        startingSessions.setLayoutConstraint(view, secondView: view)
        
        startingSessions.startAction = { type in
            
            switch type {
            case .aw:
                let vc = WatchSyncError.loadFromStoryboard()
                
                if WCSession.isSupported() {
                    let session = WCSession.default
                    
                    if !session.isPaired {
                        vc.errorConfiguration = .noAppleWatch
                        self.showWatchSyncError(vc)
                        return
                    } else if !session.isWatchAppInstalled {
                        vc.errorConfiguration = .noInstallZendo
                        self.showWatchSyncError(vc)
                        return
                    }
                }
                
                let configuration = HKWorkoutConfiguration()
                configuration.activityType = .mindAndBody
                configuration.locationType = .unknown
                self.start = Date()
                self.healthStore.startWatchApp(with: configuration) { success, error in
                    
                    guard success else {
                        
                        if error?.code == 7 {
                            vc.errorConfiguration = .needWear
                        } else {
                            let alert = UIAlertController(title: "Error", message: (error?.localizedDescription)!, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
                                self.checkHealthKit(isShow: true)
                            })
                            DispatchQueue.main.async {
                                self.present(alert, animated: true)
                            }
                        }
                        
                        self.showWatchSyncError(vc)
                        
                        return
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1) ) {
                        Mixpanel.mainInstance().track(event: "new_session")
                    }
                }
            case .movesense:
                self.start = Date()
                self.movesenseIsStart = true
                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.5) {
                        self.arenaView.isHidden = false
                        self.changeButton(isStart: true)
                        self.changeButtonSpace(isStart: true)
                    }
                    
                }
                
            }
            
        }
        
        startingSessions.closeAction = {
            self.rescan()
        }
    }
    
}


// MARK: - Action

extension StartSessionController {
    
    @objc func startSession() {
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.5) {
                self.arenaView.isHidden = false
                self.changeButton(isStart: true)
                self.changeButtonSpace(isStart: true)
            }
            
        }
        
    }
    
    @objc func endSession() {
        
        DispatchQueue.main.async {
            self.hideTime()
            self.showResults()
        }
        
    }
    
    func sampleMovesense() {
        
        var heartRate = 0.0
        
        if let name = Settings.nameMovesense {
            if let hr = movesense_to_data_cache[name] {
                heartRate = hr
                heartRateSamples.append(Double(hr) / 60.0)
            }
            
            self.showTime()
            
            if heartRateSamples.count > 2 {
                heartSDNN = standardDeviation(heartRateSamples)
                let hr = movesense_to_data_cache[name] ?? 0.0
                
                DispatchQueue.main.async {
                    
                    self.arenaView.hrv.text = Int(self.heartSDNN.rounded()).description
                    
                    self.arenaView.time.text = Int(hr).description
                    
                    self.chartHR[String(Date().timeIntervalSince1970)] = Int(hr)
                    
                    let chartHR = self.chartHR.sorted(by: <)
                    
                    self.arenaView.setChart(chartHR)
                    
                }
                
            }
            
            let metadata: [String: Any] = [
                MetadataType.time.rawValue: Date().timeIntervalSince1970.description,
                MetadataType.sdnn.rawValue: heartSDNN.description,
                MetadataType.heart.rawValue: heartRate.description,
            ]
            
            let empty = metadataWork.isEmpty ? "" : "/"
            
            for type in metadataTypeArraySmall {
                metadataWork[type.rawValue] = ((metadataWork[type.rawValue] as? String) ?? "") + empty + (metadata[type.rawValue] as! String)
            }
            
        }
    }
    
    @objc func sample(notification: NSNotification) {
        if let sample = notification.object as? [String : Any] {
            
            self.showTime()
            
            var text_hrv = ""
            var text_hr = ""
            var int_hr = 0
            
            if let raw_hrv = sample["sdnn"] as? String {
                let double_hrv = Double(raw_hrv)!.rounded()
                text_hrv = Int(double_hrv.rounded()).description
            }
            
            if let raw_hr = sample["heart"] as? String {
                let double_hr = (Double(raw_hr)! * 60).rounded()
                int_hr = Int(double_hr)
                text_hr = int_hr.description
            }
            
            DispatchQueue.main.async {
                
                self.arenaView.hrv.text = text_hrv
                
                self.arenaView.time.text = text_hr
                
                self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
                
                let chartHR = self.chartHR.sorted(by: <)
                
                self.arenaView.setChart(chartHR)
                
            }
        }
        
    }
    
    func standardDeviation(_ arr : [Double]) -> Double
    {
        let rrIntervals = arr.map
        {
            (beat) -> Double in
            
            return 1000 / beat
        }
        
        let length = Double(rrIntervals.count)
        
        let avg = rrIntervals.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = rrIntervals.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    @IBAction func startAction(_ sender: UIButton) {
        
        if sender.titleLabel?.text == "Start" {
            for (index, device) in listDevices.enumerated() {
                if device.type == .aw {
                    listDevices.remove(at: index)
                    break
                }
            }
            
            if WCSession.isSupported() {
                let session = WCSession.default
                
                if session.isPaired && session.isWatchAppInstalled {
                    
                    let device = DeviceLE(type: .aw)
                    
                    if session.isWatchAppInstalled {
                        if listDevices.isEmpty {
                            device.isSelect = true
                        }
                    }
                    
                    listDevices.append(device)
                }
                
                if listDevices.isEmpty {
                    let vc = PairStatusController.loadFromStoryboard()
                    vc.status = .noDetected
                    
                    DispatchQueue.main.async {
                        self.present(vc, animated: true)
                    }
                }
                
                startingSessions.devices = listDevices
                
                startingSessions.showView(devices: listDevices)
            }
        } else {
            end = Date()
            
            if movesenseIsStart {
                endSessionMovesense()
            } else {
                WCSession.default.sendMessage(["phone": "end"], replyHandler: { replyMessage in
                    
                }, errorHandler: { error in
                    
                })
            }
            
            movesenseIsStart = false
            
        }
        
    }
    
    
    func endSessionMovesense() {
        if #available(iOS 12.0, *) {
            
            if let startDate = self.start {
                
                var healthKitSamples: [HKSample] = []
                
                let energyUnit = HKUnit.smallCalorie()
                
                let energyValue = HKQuantity(unit: energyUnit, doubleValue: 0.0)
                
                let workout = HKWorkout(activityType: .mindAndBody, start: startDate, end: Date(), workoutEvents: nil, totalEnergyBurned: energyValue, totalDistance: nil, totalSwimmingStrokeCount: nil, device: nil, metadata: metadataWork)
                
                let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
                
                let mindfulSample = HKCategorySample(type:mindfulType, value: 0, start: startDate, end: Date())
                
                healthKitSamples.append(mindfulSample)
                
                if(self.heartRateSamples.count > 2)
                {
                    let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
                    
                    let hrvUnit = HKUnit(from: "ms")
                    
                    let quantityType = HKQuantity(unit: hrvUnit, doubleValue: self.heartSDNN)
                    
                    let hrvSample = HKQuantitySample(type: hrvType!, quantity: quantityType, start: startDate, end: Date())
                    
                    healthKitSamples.append(hrvSample)
                    
                }
                
                var allSamples : [HKSample] = healthKitSamples.map({$0})
                
                allSamples.append(workout)
                
                
                self.healthStore.save(allSamples) { success, error in
                    
                    guard error == nil else {
                        print(error.debugDescription)
                        return
                    }
                    
                    self.healthStore.add(healthKitSamples, to: workout, completion:
                        {
                            success, error in
                            
                            guard error == nil else {
                                print(error.debugDescription)
                                return
                            }
                            
                            self.showResults()
                            
                    })
                    
                }
            }
            
        } else {
            self.showResults()
        }
    }
    
    func showResults() {
        DispatchQueue.main.async {
            if let start = self.start, let end = self.end {
                self.hideTime()
                let vc = ResultsController.loadFromStoryboard()
                vc.start = start
                vc.end = end
                vc.close = {
                    self.dismiss(animated: true) {
                        self.dismiss(animated: true)
                    }
                }
                
                let nc = UINavigationController(rootViewController: vc)
                nc.modalPresentationStyle = .fullScreen
                self.present(nc, animated: true)
                
                self.start = nil
                self.end = nil
            }
        }
        
    }
    
}

// MARK: - Static

extension StartSessionController {
    
    static func loadFromStoryboard() -> StartSessionController {
        return UIStoryboard(name: "StartSession", bundle: nil).instantiateViewController(withIdentifier: "StartSessionController") as! StartSessionController
    }
    
}
