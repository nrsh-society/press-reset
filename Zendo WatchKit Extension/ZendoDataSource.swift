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
    var currentHrv : Double = 0.0
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        handler([])
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        
        
        let entry = CLKComplicationTimelineEntry(date: Date(),
                                                 complicationTemplate: getTemplate(complication: complication))
        handler(entry)
    }
    
    func getHrv() -> String {
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictEndDate)
        
        let options : HKStatisticsOptions  = HKStatisticsOptions.discreteAverage
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options)
        {
            query, result, error in
            
            if(error != nil)
            {
                print(error.debugDescription)
                
            }
            else
            {
                if let value = result!.averageQuantity()?.doubleValue(
                    for: HKUnit(from: "ms"))
                {
                    DispatchQueue.main.async()
                        {
                            if value > 0.0
                            {
                                self.currentHrv = value
                            }
                    }
                }
            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
        
        return Int(self.currentHrv).description
        
    }
    
    
    func getTemplate (complication: CLKComplication) -> CLKComplicationTemplate
    {
        var retval : CLKComplicationTemplate? = nil
        
        switch complication.family
        {
       
        case .modularSmall:
            
            let template = CLKComplicationTemplateModularSmallSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: getHrv())
            template.tintColor = .white
            
            retval = template
            
            break
            
        case .modularLarge:
            
            let template = CLKComplicationTemplateModularLargeTallBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Zendo")
            template.bodyTextProvider = CLKSimpleTextProvider(text: getHrv())
            template.tintColor = .white
            
            retval = template
            
            break
            
        case .circularSmall:
            
            let template = CLKComplicationTemplateCircularSmallSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: getHrv())
            template.tintColor = .white
            retval = template
            
            break
            
        case .extraLarge:
            
            let template = CLKComplicationTemplateExtraLargeSimpleText()
            template.textProvider = CLKSimpleTextProvider(text: getHrv())
            template.tintColor = .white
            retval = template
            
            break
            
        case .utilitarianLarge:
            
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.tintColor = .white
            retval = template
            
            break
            
        case .utilitarianSmall:
            
            let template = CLKComplicationTemplateUtilitarianSmallSquare()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(named: "Utilitarian")!)
            template.tintColor = .white
            retval = template
            
            break
            
        case .utilitarianSmallFlat:
            
            let template = CLKComplicationTemplateUtilitarianSmallFlat()
            template.textProvider = CLKSimpleTextProvider(text: getHrv())
            template.tintColor = .white
            retval = template
            
            break
            
        default:
            
            break
            
        }
    
        return retval!
    }
    
        
        func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
            handler(.showOnLockScreen)
        }
        
        func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
            
            handler(getTemplate(complication: complication))
        }
}
