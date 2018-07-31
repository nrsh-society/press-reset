//
//  ZendoDataSource.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 6/29/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit
import HealthKit

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
        
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: getTemplate(complication: complication))
        handler(entry)
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
    
    
    func getTemplate (complication: CLKComplication) -> CLKComplicationTemplate {
        var retval: CLKComplicationTemplate!
        
        switch complication.family {
        case .modularSmall:
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Modular")!)
            
            retval = template
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Circular")!)
            
            retval = template
        case .extraLarge:
            let template = CLKComplicationTemplateExtraLargeSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Extra Large")!)
            
            retval = template
        case .utilitarianSmall:
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            
            retval = template
        case .utilitarianSmallFlat:
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Complication/Utilitarian")!)
            template.textProvider = CLKSimpleTextProvider(text: "Zendo")
            retval = template
        default: break
        }
        
        return retval
    }
    
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(getTemplate(complication: complication))
    }
    
}
