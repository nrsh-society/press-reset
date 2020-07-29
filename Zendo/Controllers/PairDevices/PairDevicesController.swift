//
//  PairDevicesController.swift
//  Zendo
//
//  Created by Boris Sedov on 09.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit
import Lottie
import WatchConnectivity
import CoreBluetooth

enum TypeDeviceLE {
    case movesense, aw
}

class DeviceLE {
    var type: TypeDeviceLE
    var isSelect: Bool
    var movesenseName: String?
    var name: String {
        get {
            if type == .aw {
                return "Apple Watch"
            } else {
                return self.movesenseName ?? ""
            }
        }
    }
    
    init(type: TypeDeviceLE, movesenseName: String? = nil, isSelect: Bool = false) {
        self.type = type
        self.movesenseName = movesenseName
        self.isSelect = isSelect
    }
}

class PairDevicesController: UIViewController {
    
    // MARK: - Outlet
    
    @IBOutlet weak var zenButton: ZenButton!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(PairDevicesTableCell.nib, forCellReuseIdentifier: PairDevicesTableCell.reuseIdentifierCell)
            tableView.tableFooterView = UIView()
        }
    }
        
    // MARK: - Let
    
    let circleAnimation = AnimationView(name: "animationStartingSession")
    
    // MARK: - Var
    
    private var movesense_to_uuid_cache = [String: String]() //STORED AS MOVESENSEID:UUID
    
    private var centralManager: CBCentralManager!
    
    var listDevices = [DeviceLE]()
    var timerDetected: Timer?
    
    deinit {
        print("PairDevicesController deinit")
    }
    
}

// MARK: - LifeCycle

extension PairDevicesController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionNext()
        setCentralManager()
        setAnimation()
        startAnimation()
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        rescan()
        
    }
    
}

// MARK: - Action

extension PairDevicesController {
    
    @IBAction func rescanAction(_ sender: UIButton) {
        rescan()
    }
    
    func actionNext() {
        
        zenButton.action = { [weak self] in
            
            guard let self = self else { return }
            
            var isSelect = false
            
            for device in self.listDevices {
                if device.isSelect {
                    isSelect = true
                    
                    if device.type == .movesense {
                        Settings.nameMovesense = device.name
                    }
                    
                }
            }
            
            if isSelect {
                let vc = PairStatusController.loadFromStoryboard()
                vc.status = .paired
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
        }
        
    }
    
}

// MARK: - CoreBluetooth

extension PairDevicesController: CBCentralManagerDelegate {
    
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
        
        if let movesense_id = advertisementData["kCBAdvDataLocalName"] as? String, movesense_id.hasPrefix("Movesense") {
            
            if movesense_to_uuid_cache[movesense_id] == nil {
                movesense_to_uuid_cache[movesense_id] = peripheral.identifier.uuidString
                
                var isSelect = true
                
                for device in listDevices {
                    if device.type == .movesense {
                        isSelect = false
                        break
                    }
                }
                
                let device = DeviceLE(type: .movesense, movesenseName: movesense_id, isSelect: isSelect)
                listDevices.append(device)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                checkButton()
                
            } else if let _ = movesense_to_uuid_cache[movesense_id] {
                movesense_to_uuid_cache[movesense_id] = peripheral.identifier.uuidString
            }
            
        }
        
    }
    
}

// MARK: - UITableViewDelegate

extension PairDevicesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectDevice = listDevices[indexPath.row]
        
        switch selectDevice.type {
        case .movesense:
            
            for (index, device) in listDevices.enumerated() {
                if device.type == .movesense {
                    if selectDevice.name == device.name {
                        listDevices[index].isSelect = true
                    } else {
                        listDevices[index].isSelect = false
                    }
                }
            }
            
            tableView.reloadData()
            
        case .aw:
            
            checkAppInstalled(device: selectDevice)
            
        }
        
    }
    
}

// MARK: - UITableViewDataSource

extension PairDevicesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PairDevicesTableCell.reuseIdentifierCell, for: indexPath) as! PairDevicesTableCell
        
        cell.nameLabel.text = listDevices[indexPath.row].name
        cell.imageCheck.isHidden = !listDevices[indexPath.row].isSelect
        
        return cell
    }
    
}

// MARK: - Methods

extension PairDevicesController {
    
    func setCentralManager() {
        let centralQueue: DispatchQueue = DispatchQueue(label: "tools.sunyata.zendo", attributes: .concurrent)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    func setAnimation() {
        animationView.insertSubview(circleAnimation, at: 0)
        
        circleAnimation.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        circleAnimation.contentMode = .scaleAspectFill
        circleAnimation.frame = animationView.bounds
        circleAnimation.loopMode = .loop
        circleAnimation.animationSpeed = 0.6
    }
    
    func startAnimation() {
        animationView.isHidden = false
        tableView.isHidden = true
        circleAnimation.play()
    }
    
    func stopAnimation() {
        animationView.isHidden = true
        tableView.isHidden = false
        circleAnimation.stop()
    }
    
    func startTimer() {
        timerDetected?.invalidate()
        timerDetected = Timer.scheduledTimer(
            withTimeInterval: 90,
            repeats: false,
            block: { [weak self] timer in
                
                guard let self = self else { return  }
                
                self.timerDetected?.invalidate()
                self.timerDetected = nil
                
                if self.listDevices.isEmpty {
                    let vc = PairStatusController.loadFromStoryboard()
                    vc.status = .noDetected
                    
                    DispatchQueue.main.async {
                        self.present(vc, animated: true)
                    }
                } else {
                    self.startTimer()
                }
                
        })
    }
    
    func checkWatch() {
        if WCSession.isSupported() {
            let session = WCSession.default
            
            if session.isPaired {
                
                let device = DeviceLE(type: .aw)
                
                if session.isWatchAppInstalled {
                    device.isSelect = true
                }
                
                
                listDevices.append(device)
                stopAnimation()
                tableView.reloadData()
                checkButton()
            }
        }
    }
    
    func checkButton() {
                
        var isHidden = true
                
        for device in listDevices {
            if device.isSelect {
                isHidden = false
                break
            }
        }
        
        DispatchQueue.main.async {
            self.zenButton.isHidden = isHidden
        }
        
    }
    
    func checkAppInstalled(device: DeviceLE) {
        if WCSession.isSupported() {
            let session = WCSession.default
            
            if session.isPaired {
                
                if session.isWatchAppInstalled {
                    device.isSelect = true
                } else {
                    let vc = WatchSyncError.loadFromStoryboard()
                    vc.errorConfiguration = .noInstallZendo
                    if #available(iOS 13.0, *) {
                        vc.modalPresentationStyle = .automatic
                    } else {
                        vc.modalPresentationStyle = .currentContext
                    }
                    vc.modalTransitionStyle = .coverVertical
                    present(vc, animated: true)
                }
                
            }
        }
    }
    
    func rescan() {
        movesense_to_uuid_cache.removeAll()
        listDevices.removeAll()
        tableView.reloadData()
        startAnimation()
        checkWatch()
        startTimer()
    }
}

// MARK: - Static

extension PairDevicesController {
    
    static func loadFromStoryboard() -> PairDevicesController {
        return UIStoryboard(name: "PairDevices", bundle: nil).instantiateViewController(withIdentifier: "PairDevicesController") as! PairDevicesController
    }
    
}
