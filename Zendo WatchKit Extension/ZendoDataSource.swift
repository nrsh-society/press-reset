//
//  ZendoDataSource.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 6/29/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import HealthKit
import ClockKit


 class ZendoDataSource: NSObject, CLKComplicationDataSource
{
    var currentHrv = 0.0
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    /*
     func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
     print("getNextRequestedUpdateDate")
     handler(Date(timeIntervalSinceNow: 120))
     }
     
     func requestedUpdateDidBegin() {
     print("requestedUpdateDidBegin")
     let server = CLKComplicationServer.sharedInstance()
     for complication in server.activeComplications! {
     server.reloadTimeline(for: complication)
     }
     }*/
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        print("getCurrentTimelineEntry")
        
        if let template = getTemplate(complication: complication)
        {
        
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            
            handler(entry)
            
        } else
        {
            handler(nil)
        }
        
    }
    
    func getHrv() -> String {
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictEndDate)
        
        let options : HKStatisticsOptions  = HKStatisticsOptions.discreteAverage
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) { query, result, error in
                                            
                                            if error != nil {
                                                print(error.debugDescription)
                                            } else {
                                                if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                    
                                                    DispatchQueue.main.async() {
                                                        if value > 0.0 {
                                                            self.currentHrv = value
                                                        }
                                                    }
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
        return Int(self.currentHrv).description
    }
    
    
    func getTemplate (complication: CLKComplication) -> CLKComplicationTemplate? {
        var retval: CLKComplicationTemplate?
        
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Modular")!)
            template.tintColor = UIColor.zenLightGreen
            retval = template
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!)
            template.tintColor = UIColor.zenLightGreen
            retval = template
        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Extra Large")!)
            template.tintColor = UIColor.zenLightGreen
            retval = template
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.tintColor = UIColor.zenLightGreen
            retval = template
        case .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKSimpleTextProvider(text: "Zendo")
            template.tintColor = UIColor.zenLightGreen
            retval = template
        default: break
        }
        
        return retval ?? nil
    }
    
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(getTemplate(complication: complication))
    }
    
}

extension UIColor {
    
    static var zenDarkGreen: UIColor { //#478C78
        return UIColor(red: 0.28, green: 0.55, blue: 0.47, alpha: 1.0)
    }
    
    static var zenLightGreen: UIColor { //#95AFA5
        return UIColor(red: 0.58, green: 0.69, blue: 0.65, alpha: 1.0)
    }
    
}
