//
//  ZendoDataSource.swift
//  Zendo WatchKit Extension
//
//  Created by Douglas Purdy on 6/29/18.
//  Copyright © 2018 zenbf. All rights reserved.
//

import WatchKit

class ZendoDataSource: NSObject, CLKComplicationDataSource
{
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void)
    {
        handler([])
    }
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void)
    {
        if complication.family == .modularSmall {
            
            let template = CLKComplicationTemplateModularSmallStackImage()
            template.line1ImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "shobogenzo")!)
            template.line2TextProvider = CLKSimpleTextProvider(text: "66")
            template.tintColor = .white
        
            let entry = CLKComplicationTimelineEntry(date: Date(),
                                                 complicationTemplate: template)
            handler(entry)
        }
        else
        {
            handler(nil)
        }
    }
    
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        
        
        if complication.family == .modularSmall {
            
            let template = CLKComplicationTemplateModularSmallStackImage()
            template.line1ImageProvider = CLKImageProvider(onePieceImage: UIImage(named: "shobogenzo")!)
            template.line2TextProvider = CLKSimpleTextProvider(text: "66")
            template.tintColor = .white

        handler(template)
        } else {
            handler(nil)
        }
    }
    
}

