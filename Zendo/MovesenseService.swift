import Foundation
import PromiseKit
import SwiftyJSON

/// The main class for using the services from Movesense devices.
/// This class offers a way to enumerate the devices and receive connected/disconnected
/// callbacks when the devices become available
final public class MovesenseService: NSObject {
    private let FOUND_EVENT = "deviceFound"
    private let LOST_EVENT = "deviceLost"
    internal var mds: MDSWrapper!
    private var subscriptions = Dictionary<String, Bool>()
    private var devices = Dictionary<UUID, MovesenseDevice>()
    private var bleController: BleController!
    private var deviceConnectedCb: (String) -> () = { (serial) in }
    private var deviceDisconnectedCb: (String) -> () = { (serial) in }
    private var bleOnOffCbs: Array<(Bool) -> ()> = []
    private var mdsUriPrefix: String = "suunto://MDS/"

    public override init() {
        super.init()
        self.mds = MDSWrapper()
        self.bleController = BleController()
        self.subscribeToDeviceConnections()
    }

    public func shutdown() {
        self.mds!.deactivate();
    }

    /// Call after constructing an instance of MovesenseService.
    /// Specify callbacks to handle connected/disconnected device
    /// notifications as well as BLE on/off notifications.
    public func setHandlers(deviceConnected: @escaping (String) -> (),
                            deviceDisconnected: @escaping (String) -> (),
                            bleOnOff: @escaping (Bool) -> ()) {
        self.deviceConnectedCb = deviceConnected
        self.deviceDisconnectedCb = deviceDisconnected
        self.bleController.bleOnOff = bleOnOff

        bleOnOff(self.bleController.isBleOn())
    }
    
    public func deviceFound(_ uuidStr:String, serial:String, deviceInfo:String) {
        let response = MovesenseResponse(serial: serial, path: "/info", content: deviceInfo)

        let content = response.asDict()
        let manufacturerName = content["manufacturerName"]
        let productName = content["productName"] as! String
        let variant = content["variant"] as! String
        let sw = content["sw"] as! String
        let hw = content["hw"] as! String
        let serial = content["serial"] as! String
        let info = MovesenseDeviceInfo(hw: hw, sw: sw, manufacturerName: manufacturerName as! String, productName:productName, variant: variant, serial: serial)

        if let uuid = UUID(uuidString: uuidStr) {
            self.devices[uuid]?.mdsConnected = true
            self.devices[uuid]?.serial = serial
            self.devices[uuid]?.deviceInfo = info
        }
        self.deviceConnectedCb(serial)
    }
    
    public func deviceLost(_ serial:String) {
        let uuid = self.devices.first(where: { (key, value) -> Bool in
            return (value.serial == serial)
        })?.value.uuid

        if (uuid != nil) {
            self.devices[uuid!]?.mdsConnected = false
            self.devices[uuid!]?.bleStatus = false;
        }

        self.deviceDisconnectedCb(serial)
    }

    public func subscribeToDeviceConnections() {
        self.mds!.doSubscribe("MDS/ConnectedDevices",
                              contract: [:],
                              response: { (response) in
                                    print("Subscribed to connected devices (\(response)(")
                                    if response.statusCode != 200 {
                                        print("Failed to subscribe connected devices: \(response.header)")
                                    }
                                },
                              onEvent: { (event) in
                                    let json = try! JSON(data: event.bodyData)
                                    let method = json["Method"].stringValue
                                    if method == "POST" {
                                        // Connect
                                        print("Connected device: \(event)")
                                        let info = json["Body"]["DeviceInfo"].rawString()
                                        let uuid = json["Body"]["Connection"]["UUID"].stringValue
                                        self.deviceFound(uuid, serial: json["Body"]["Serial"].stringValue, deviceInfo: info != nil ? info!: "")
                                    } else if method == "DEL" {
                                        // Disconnect
                                        print("Disconnected device: \(event)")
                                        self.deviceLost(json["Body"]["Serial"].stringValue)
                                }
                            })
    }
   
    /// Check if the specified device is connected through MDS
    public func isDeviceConnected(_ serial: String) -> Bool {
        let connected = self.devices.first(where: { (key, value) -> Bool in
            return value.serial == serial
        })?.value.mdsConnected

        return (connected != nil) ? connected! : false
    }

    /// Get information about the specific Movesense device
    public func getDevice(_ serial: String) -> MovesenseDevice? {
        return self.devices.first(where: { (key, value) -> Bool in
            return value.serial == serial
        })?.value
    }

    /// Get information about the specific Movesense device
    public func getDevice(_ uuid: UUID) -> MovesenseDevice? {
        return self.devices.first(where: { (key, value) -> Bool in
            return uuid == key
        })?.value
    }

    /// Get the total number of enumerated Movesense devices
    public func getDeviceCount() -> Int {
        return self.devices.count
    }
    
    /// Get information about the nth Movesense device from the enumerated devices
    public func nthDevice(_ n: Int) -> MovesenseDevice? {
        var i = 0
        for (_, device) in self.devices {
            if i == n {
                return device
            }
            i = i + 1
        }
        return nil
    }
    
    /// Start looking for Movesense devices
    public func startScan(_ deviceFound: @escaping (MovesenseDevice) -> ()) -> Promise<Void> {
        return Promise { seal in
            self.bleController.startScan(deviceFound: { device in
                                             self.devices[device.uuid] = device
                                             deviceFound(device)
                                         },
                                         scanReady: {
                                             seal.fulfill(())
                                         })
        }
    }

    /// Stop looking for Movesense devices
    public func stopScan() {
        self.bleController.stopScan()
    }

    /// Establish a connection to the specific Movesense device
    public func connectDevice(_ serial: String) {
        //self.bleController.stopScan(); //This line is preventing multiple movesense sensors from having the opportunity to connect -Mayur
        let device = self.getDevice(serial)!
        self.mds.connectPeripheral(with: device.uuid);
    }

    /// Disconnect specific Movesense device
    public func disconnectDevice(_ serial: String) {
        let device = self.getDevice(serial)!
        self.mds.disconnectPeripheral(with: device.uuid);
    }

    /// Subscribe to a specified resource
    public func subscribe(_ serial: String, path: String,
                          parameters: Dictionary<String, Any>,
                          onNotify: @escaping (MovesenseResponse) -> (),
                          onError: @escaping (String, String, String) -> ()) {

        let uri = String("\(serial)\(path)");
        self.mds!.doSubscribe(uri,
                              contract: parameters,
                              response: { (response) in
                                    print("Response: \(response)")
                                    if response.statusCode < 300 {
                                         self.subscriptions[uri] = true
                                    } else {
                                        onError(self.getSerial(response.header["Uri"] as! String),
                                                self.getPath(response.header["Uri"] as! String),
                                                response.header["Reason"] as! String)
                                    }
                                },
                              onEvent: { (event) in
                                    onNotify(self.convertEvent(event))
                                })
    }
    
    /// Check if the given resource is subscribed
    public func isSubscribed(_ serial: String, path: String) -> Bool {
        return self.subscriptions.contains { key, _ -> Bool in
            return key == String("\(serial)\(path)")
        }
    }
    
    /// Unsubscribe from a specified resource. Must have been subscribed before.
    public func unsubscribe(_ serial: String, path: String) {
        let uri = String("\(serial)\(path)")
        self.mds!.doUnsubscribe(uri)
        self.subscriptions.removeValue(forKey: uri)
    }
    
    /// Returns a promise for asynchronous put request to the specified Movesense resource.
    /// Please check the required parameters from the relevant interface descriptions.
    /// For example time is set using path /Time and {"value": 1479921403}
    public func put(_ serial: String, path: String, parameters: Dictionary<String, Any>) -> Promise<MovesenseResponse> {
        return Promise { seal in
            self.mds!.doPut(String("\(serial)\(path)"),
                            contract: parameters,
                            completion: { (response) in
                                print("Response: \(response)")
                                if response.statusCode < 300 {
                                    seal.fulfill(self.convertResponse(response))
                                } else {
                                    seal.reject(NSError(domain: response.header["Reason"] as! String, code: Int(response.statusCode), userInfo: nil))
                                }
                            })
        }
    }
    
    /// Returns a promise for asynchronous get request to the specified Movesense resource
    public func get(_ serial: String, path: String, parameters: Dictionary<String, Any> = [:]) -> Promise<MovesenseResponse> {
        return Promise { seal in
            self.mds!.doGet(String("\(serial)\(path)"),
                            contract: parameters,
                            completion: { (response) in
                                print("Response: \(response)")
                                if response.statusCode < 300 {
                                    seal.fulfill(self.convertResponse(response))
                                } else {
                                    seal.reject(NSError(domain: response.header["Reason"] as! String, code: Int(response.statusCode), userInfo: nil))
                                }
                            })
        }
    }

    public func del(_ serial: String, path: String, parameters: Dictionary<String, Any> = [:]) -> Promise<MovesenseResponse> {
        return Promise { seal in
            self.mds!.doDelete(String("\(serial)\(path)"),
                            contract: parameters,
                            completion: { (response) in
                                print("Response: \(response)")
                                if response.statusCode < 300 {
                                    seal.fulfill(self.convertResponse(response))
                                } else {
                                    seal.reject(NSError(domain: response.header["Reason"] as! String, code:         Int(response.statusCode), userInfo: nil))
                                }
            })
        }
    }

    public func getSerial(_ uri: String) -> String {
        if String(uri.prefix(self.mdsUriPrefix.count)) == mdsUriPrefix {
            // from MDS own resource
            return "MDS"
        } else {
            // from device
            let index = uri.index(of: "/") ?? uri.endIndex
            let serial = uri[uri.startIndex..<index]
            return String(serial)
        }
    }

    private func getPath(_ uri: String) -> String {
        if String(uri.prefix(mdsUriPrefix.count)) == mdsUriPrefix {
            // from MDS own resource
            let index = uri.index(uri.startIndex, offsetBy: mdsUriPrefix.count)
            let path = uri[uri.index(after: index)..<uri.endIndex]
            return String(path)
        } else {
            // from device
            if let index = uri.index(of: "/") {
                let path = uri[uri.index(after: index)..<uri.endIndex]
                return String(path)
            } else {
                return uri;
            }
        }
    }

    private func convertResponse(_ response: MDSResponse) -> MovesenseResponse {
        var contentString: String!
        var json: JSON?
        do {
            json = try JSON(data: response.bodyData)
            if json!["Content"].exists() {
                contentString = json!["Content"].rawString()
            } else {
                contentString = json!.rawString()
            }
        } catch {
            contentString = nil
        }
        return MovesenseResponse(serial: self.getSerial(response.header["Uri"] as! String),
                                 status: response.statusCode,
                                 path: self.getPath(response.header["Uri"] as! String),
                                 content: (contentString != nil) ? contentString! : "")
    }

    private func convertEvent(_ event: MDSEvent) -> MovesenseResponse {
        let json = try! JSON(data: event.bodyData)
        let contentString = json["Body"].rawString()
        return MovesenseResponse(serial: self.getSerial(event.header["Uri"] as! String),
                                 path: self.getPath(event.header["Uri"] as! String),
                                 content: (contentString != nil) ? contentString! : "")
    }
}


public struct MovesenseDeviceInfo {
    public var hw: String
    public var sw: String
    public var manufacturerName: String
    public var productName: String
    public var variant: String
    public var serial: String
}

public struct MovesenseDevice {
    public var uuid: UUID
    public var localName: String
    public var serial: String // Must be unique among all devices
    public var bleStatus: Bool
    public var mdsConnected: Bool = false
    public var deviceInfo: MovesenseDeviceInfo?

    init(uuid: UUID, localName: String, serial: String,
         info: MovesenseDeviceInfo?, linkStatus: Bool)
    {
        self.uuid = uuid
        self.localName = localName
        self.serial = serial
        self.bleStatus = linkStatus
        self.deviceInfo = info
    }
}


/// Represents the response to a request from a Movesense device
public struct MovesenseResponse {
    /// The device identifier
    public let serial: String
    /// Status code of the request
    public var status: Int = 0
    /// The path this response is from
    public let path: String
    /// The response content as JSON
    public let content: String

    init(serial: String, path: String, content: String) {
        self.serial = serial
        self.path = path
        self.content = content
    }

    init(serial: String, status: Int, path: String, content: String) {
        self.serial = serial
        self.status = status
        self.path = path
        self.content = content
    }

    /// Parse the JSON response as NSDictionary
    public func asDict() -> NSDictionary {
        let data = self.content.data(using: .utf8)!
        return try! JSONSerialization.jsonObject(with: data) as! NSDictionary
    }
}

public struct Vector3D {
    public let x: Double
    public let y: Double
    public let z: Double
    public func total() -> Double {
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    }
}

public struct DataVectors {
    public let time: UInt32
    public let vectors: Array<Vector3D>
}

public struct LogEntry {
    public let id: UInt32
    public let modificationTimestamp: UInt32
    public let size: UInt64
}

public struct LogEntries {
    public let entries: [LogEntry]
    public init(entries:[LogEntry]) {self.entries = entries;}
}

extension MovesenseResponse {
    /// Extension method to cast the JSON response to LogEntries struct
    public func asLogEntries() -> LogEntries {
        // "{\"elements\": [{\"Id\": 1481803105, \"ModificationTimestamp\": 1481803674, \"Size\": 7672}, {\"Id\": 1481873449, \"ModificationTimestamp\": 1481875132, \"Size\": 55020}]}"
        let content = self.asDict()
        let elements = content["elements"] as! NSArray
        let entries = elements.map{ ii -> LogEntry in
            let item = ii as! NSDictionary
            let id = item["Id"] as! UInt32
            let modificationTimestamp = item["ModificationTimestamp"] as! UInt32
            let size = item["Size"] as! UInt64
            return LogEntry(id: id, modificationTimestamp: modificationTimestamp, size: size)
        }
        return LogEntries(entries: entries)
    }

    public func getVectors(_ vectorField: String) -> DataVectors {
        let content = asDict()
        let time = content["Timestamp"] as? UInt32
        let vectorArray = content[vectorField] as? NSArray

        var vectors = [Vector3D]()
        if vectorArray != nil {
            for item in vectorArray! {
                let vector = item as! NSDictionary
                let x = vector["x"] as! Double
                let y = vector["y"] as! Double
                let z = vector["z"] as! Double
                let v = Vector3D(x: x, y: y, z: z)
                vectors.append(v)
            }
        }

        return DataVectors(time: time != nil ? time! : 0, vectors: vectors)
    }
}
