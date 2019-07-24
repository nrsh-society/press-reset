import Foundation
import UIKit
import PromiseKit
import CoreBluetooth
import Movesense


final class BleController: NSObject, CBCentralManagerDelegate {
    static let SCAN_TIMEOUT = 15.0
    
    private var centralManager: CBCentralManager?
    private var scanTimer = Timer() //!< When timer triggers, scanning is stopped
    private var knownDevices = Dictionary<UUID, String>() //!< Map UUID to local name
    private let (prom, sea) = Promise<() -> ()>.pending()
    private var knownDevicesPromise: Promise<Void>?
    var bleOnOff: ((Bool) -> ())?
    private var addDeviceCallback: (MovesenseDevice) -> () = { (device) in }
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options:nil)
    }

    private func isKnown(uuid: UUID) -> Bool {
        return self.knownDevices.contains { elem in
            elem.key == uuid
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        
        switch state {
        case CBManagerState.poweredOff:
            self.bleOnOff?(false)
        case CBManagerState.poweredOn:
            self.bleOnOff?(true)
            self.retrieveFromSystem()
        default:
            () // Nothing to do
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber)
    {
        print("didDiscoverPeripheral: \(peripheral)")

        let uuid = peripheral.identifier
        if (advertisementData.contains { key, _ in key == CBAdvertisementDataLocalNameKey})
        {
            let localName = advertisementData[CBAdvertisementDataLocalNameKey] as! String
            
            if !localName.isEmpty && isMovesense(localName) {
                // Show only Movesense devices as the others are not able to connect with the attached lib
                let serial = self.parseSerial(localName)
                self.knownDevices[uuid as UUID] = localName
                let device = MovesenseDevice(uuid: uuid as UUID, localName: localName, serial: serial, info: nil, linkStatus: false)
                self.addDeviceCallback(device)
            }
        }
    }
    
    func startScan(deviceFound: @escaping (MovesenseDevice) -> (), scanReady: @escaping () -> ()) {
        if (self.centralManager?.isScanning)! {
            return
        }

        self.addDeviceCallback = deviceFound

        self.centralManager?.scanForPeripherals(withServices: Movesense.MOVESENSE_SERVICES, options:
            [CBCentralManagerScanOptionAllowDuplicatesKey: true]);

        self.scanTimer.invalidate()

        Timer.scheduledTimer(withTimeInterval: BleController.SCAN_TIMEOUT, repeats: true, block: { _ in
            self.stopScan()
            scanReady()
        })

        self.retrieveFromSystem()
    }

    func stopScan() {
        self.scanTimer.invalidate()

        if !(self.centralManager?.isScanning)! {
            return
        }

        if self.centralManager?.state == .poweredOn {
            self.centralManager?.stopScan()
        }
    }

    private func isMovesense(_ localName: String) -> Bool {
        let index = localName.index(of: " ") ?? localName.endIndex
        return localName[localName.startIndex..<index] == "Movesense"
    }

    private func parseSerial(_ localName: String) -> String {
        if let idx = localName.range(of: " ", options: .backwards)?.lowerBound {
            let serialName = localName[localName.index(after: idx)..<localName.endIndex]
            return String(serialName)
        } else {
            return localName
        }
    }

    func retrieveFromSystem()
    {
        // Fetch the peripherals already known to the system
        let connected = self.centralManager!.retrieveConnectedPeripherals(withServices: Movesense.MOVESENSE_SERVICES)
        for peripheral in connected
        {
            print("Found known device: \(peripheral)")
            let uuid = peripheral.identifier
            let localName = peripheral.name!

            if isMovesense(localName) {
                // Show only Movesense devices as the others are not able to connect with the attached lib
                let serial = self.parseSerial(localName)
                let device = MovesenseDevice(uuid: uuid as UUID,
                                             localName: localName,
                                             serial: serial,
                                             info: nil,
                                             linkStatus: true)
                
                self.addDeviceCallback(device)

                self.knownDevices[uuid as UUID] = localName
            }
        }
    }

    func isBleOn() -> Bool {
        return (self.centralManager?.state == .poweredOn)
    }
}

