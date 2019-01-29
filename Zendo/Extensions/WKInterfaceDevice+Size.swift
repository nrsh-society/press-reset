//
//  WKInterfaceDevice+Size.swift
//  Zendo
//
//  Created by Anton Pavlov on 29/01/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import WatchKit


enum DeviceType {
    case AWS0_38, AWS0_42, AWS1_38, AWS1_42, AWS2_38, AWS2_42, AWS3_38, AWS3_42, AWS4_40, AWS4_44
    case simulator
    case unknown
}

extension WKInterfaceDevice {
    
    static var AW38: Bool {
        let smallTypes: [DeviceType] = [.AWS0_38, .AWS1_38, .AWS2_38, .AWS3_38]
        return smallTypes.contains(deviceType)
    }
    
    static var AW42: Bool {
        let smallTypes: [DeviceType] = [.AWS0_42, .AWS1_42, .AWS2_42, .AWS3_42]
        return smallTypes.contains(deviceType)
    }
    
    static var AW40: Bool {
        let smallTypes: [DeviceType] = [.AWS4_40]
        return smallTypes.contains(deviceType)
    }
    
    static var AW44: Bool {
        let smallTypes: [DeviceType] = [.AWS4_44]
        return smallTypes.contains(deviceType)
    }
    
    static var identifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    static var deviceType: DeviceType {
        let id = identifier
        
        switch id {            
        case "Watch1,1":                                return .AWS0_38
        case "Watch1,2":                                return .AWS0_42
            
        case "Watch2,6":                                return .AWS1_38
        case "Watch2,7":                                return .AWS1_42
            
        case "Watch2,3":                                return .AWS2_38
        case "Watch2,4":                                return .AWS2_42
            
        case "Watch3,1", "Watch3,3":                    return .AWS3_38
        case "Watch3,2", "Watch3,4":                    return .AWS3_42
            
        case "Watch4,1", "Watch4,3":                    return .AWS4_40
        case "Watch4,2", "Watch4,4":                    return .AWS4_44
            
        case "i386", "x86_64":                          return .simulator
            
        default: return .unknown
        }
    }
    
}
