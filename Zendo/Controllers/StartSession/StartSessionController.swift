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
    private var movesense_to_data_cache = [String: (Float, String)]()
    
    private var centralManager: CBCentralManager!
    
    var chartHR = [String: Int]()
    
    var idHero = ""
    
    var listDevices = [DeviceLE]()
   
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
        
        guard let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID], let _ = uuids.first?.uuidString else { return }
        
        if uuid_to_movesense_cache[peripheral.identifier.uuidString] != nil {
            
            var bytes=[UInt8](repeating:0, count:16)
            var hr_bytes=[UInt8](repeating:0, count:4)
            var batt_byte=[UInt8](repeating:0, count:1)
            let payload: NSData = advertisementData["kCBAdvDataManufacturerData"] as! NSData
            payload.getBytes(&bytes,length:15)
            
            var hr:Float = 0
            var batt:UInt8 = 0
            var batt_level = ""
            for i in 7...10 {
                hr_bytes[i-7]=bytes[i]
            }
            
            batt_byte[0]=bytes[14]
            memcpy(&hr,&hr_bytes,4)
            memcpy(&batt,&batt_byte,1)
            if batt == 1 {
                batt_level="Battery Full"
            } else {
                batt_level="Battery Low"
            }
            
            if let key = uuid_to_movesense_cache[peripheral.identifier.uuidString] {
                movesense_to_data_cache[key] = (hr, batt_level)
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
                                               selector: #selector(self.sample),
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
                
                break
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
        if Settings.isSensorConnected {
            
            DispatchQueue.main.async {
                
                UIView.animate(withDuration: 0.5) {
                    self.arenaView.isHidden = false
                    self.startButton.setTitle("End", for: .normal)
                }
                
            }
            
        }
    }
    
    @objc func endSession() {
        
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
        
    }
    
    @objc func sample(notification: NSNotification) {
        if let sample = notification.object as? [String : Any] {
            let raw_hrv = sample["sdnn"] as! String
            let double_hrv = Double(raw_hrv)!.rounded()
            let text_hrv = Int(double_hrv.rounded()).description
            
            let raw_hr = sample["heart"] as! String
            let double_hr = (Double(raw_hr)! * 60).rounded()
            let int_hr = Int(double_hr)
            let text_hr = int_hr.description
            
            DispatchQueue.main.async {
                
                self.arenaView.hrv.text = text_hrv
                
                self.arenaView.time.text = text_hr
                
                self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
            
                let chartHR = self.chartHR.sorted(by: <)

                self.arenaView.setChart(chartHR)
                
            }
        }
        
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
                
                startingSessions.showView(devices: listDevices)
            }
        } else {
            dismiss(animated: true)
        }
                
    }
}

// MARK: - Static

extension StartSessionController {
    
    static func loadFromStoryboard() -> StartSessionController {
        return UIStoryboard(name: "StartSession", bundle: nil).instantiateViewController(withIdentifier: "StartSessionController") as! StartSessionController
    }
    
}
