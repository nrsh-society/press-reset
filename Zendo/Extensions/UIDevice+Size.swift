//
//  UIDevice+Size.swift
//  Finance
//
//  Created by Anton Pavlov on 21/11/2017.
//  Copyright © 2017 Anton Pavlov. All rights reserved.
//

import UIKit

enum DeviceType {
    case iPod5, iPod6
    case iPhone4, iPhone4S, iPhone5, iPhone5S, iPhone5C, iPhoneSE
    case iPhone6, iPhone6Plus, iPhone6S, iPhone6SPlus, iPhone7, iPhone7Plus, iPhone8, iPhone8Plus
    case iPhoneX, iPhoneXr, iPhoneXs, iPhoneXsMax
    case iPhone11, iPhone11Pro, iPhone11ProMax
    case iPad2, iPad3, iPad4, iPad5, iPadAir, iPadAir2, iPadMini, iPadMini2, iPadMini3, iPadMini4
    case iPadPro, iPadPro2
    case AppleTV, AppleTV4k
    case AirPods
    case simulator
    case unknown
}

extension UIDevice {
    
    static var small: Bool {
        let types: [DeviceType] = [.iPod5, .iPod6, .iPhone4, .iPhone4S, .iPhone5, .iPhone5S, .iPhone5C, .iPhoneSE]
        return types.contains(deviceType)
    }
    
    static var normal: Bool {
        let types: [DeviceType] = [.iPhone6, .iPhone6S, .iPhone7, .iPhone8]
        return types.contains(deviceType)
    }
    
    static var plus: Bool {
        let types: [DeviceType] = [.iPhone6Plus, .iPhone6SPlus, .iPhone7Plus, .iPhone8Plus]
        return types.contains(deviceType)
    }
    
    static var X: Bool {
        let types: [DeviceType] = [.iPhoneX,
                                   .iPhoneXr, .iPhoneXs, .iPhoneXsMax,
                                   .iPhone11, .iPhone11Pro, .iPhone11ProMax]
        return types.contains(deviceType)
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
        case "AirPods1,1":                              return .AirPods
        case "iPod5,1":                                 return .iPod5
        case "iPod7,1":                                 return .iPod6
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return .iPhone4
        case "iPhone4,1":                               return .iPhone4S
            
        case "iPhone5,1", "iPhone5,2":                  return .iPhone5
        case "iPhone5,3", "iPhone5,4":                  return .iPhone5C
        case "iPhone6,1", "iPhone6,2":                  return .iPhone5S
            
        case "iPhone7,2":                               return .iPhone6
        case "iPhone7,1":                               return .iPhone6Plus
            
        case "iPhone8,1":                               return .iPhone6S
        case "iPhone8,2":                               return .iPhone6SPlus
            
        case "iPhone8,4":                               return .iPhoneSE
            
        case "iPhone9,1", "iPhone9,3":                  return .iPhone7
        case "iPhone9,2", "iPhone9,4" :                 return .iPhone7Plus
            
        case "iPhone10,1", "iPhone10,4":                return .iPhone8
        case "iPhone10,2", "iPhone10,5":                return .iPhone8Plus
            
        case "iPhone10,3", "iPhone10,6":                return .iPhoneX
            
        case "iPhone11,8":                              return .iPhoneXr
        case "iPhone11,2":                              return .iPhoneXs
        case "iPhone11,4", "iPhone11,6":                return .iPhoneXsMax
        
        case "iPhone12,1":                              return .iPhone11
        case "iPhone12,3":                              return .iPhone11Pro
        case "iPhone12,5":                              return .iPhone11ProMax
                        
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return .iPad2
        case "iPad3,1", "iPad3,2", "iPad3,3":           return .iPad3
        case "iPad3,4", "iPad3,5", "iPad3,6":           return .iPad4
            
        case "iPad4,1", "iPad4,2", "iPad4,3":           return .iPadAir
        case "iPad5,3", "iPad5,4":                      return .iPadAir2
            
        case "iPad2,5", "iPad2,6", "iPad2,7":           return .iPadMini
        case "iPad4,4", "iPad4,5", "iPad4,6":           return .iPadMini2
        case "iPad4,7", "iPad4,8", "iPad4,9":           return .iPadMini3
        case "iPad5,1", "iPad5,2":                      return .iPadMini4
            
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return .iPadPro
        case "iPad7,1", "iPad7,2", "iPad7,3", "iPad7,4":return .iPadPro2
            
        case "iPad6,11", "iPad6,12":                    return .iPad5
            
        case "AppleTV5,3", "AppleTV6,2":                return .AppleTV
            
        case "i386", "x86_64":                          return .simulator
            
        default: return .unknown
        }
    }
}

