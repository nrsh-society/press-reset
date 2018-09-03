//
//  InterfaceController.swift
//  Zazen WatchKit Extension
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

//var _currentSession : Session?

class AppInterfaceController: WKInterfaceController {
    
    @IBOutlet var hrvLabel: WKInterfaceLabel!
    
    @IBAction func start() {
        
        NSLog("start press")
        
        startSession()
        
    }
    
    func startSession() {
        
        Session.current = Session()
        
        Session.current?.start()
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context:  Session.current  as AnyObject), (name: "OptionsInterfaceController", context: Session.current  as AnyObject)])
        
    }
    
    override func awake(withContext context: Any?){
        super.awake(withContext: context)
    }
    
    override func willActivate(){
        super.willActivate()
        
        ZBFHealthKit.getPermissions()
        
        let hkType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.autoupdatingCurrent.startOfDay(for: Date())
    
        //Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictEndDate)
        
        let options = HKStatisticsOptions.discreteAverage
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) { query, result, error in
                                            
                                            if error != nil {
                                                print(error.debugDescription)
                                            } else {
                                                if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                    DispatchQueue.main.async() {
                                                        if value > 0.0 {
                                                            self.hrvLabel.setText(Int(value).description)
                                                        }
                                                    }
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        // This method is called when watch view controller is no longer visible
    }
    
}
