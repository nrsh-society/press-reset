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

var _currentSession : Session?

class AppInterfaceController: WKInterfaceController {

    @IBOutlet var hrvLabel: WKInterfaceLabel!
    
    @IBAction func start() {
        
        NSLog("start press");
        
        startSession();
        
    }
    
    
    func startSession() {

        _currentSession = Session();
        
        _currentSession?.start();
        
        WKInterfaceDevice.current().play(WKHapticType.start)
        
        WKInterfaceController.reloadRootControllers(withNamesAndContexts: [(name: "SessionInterfaceController", context: _currentSession  as AnyObject)
            , (name: "OptionsInterfaceController", context: _currentSession  as AnyObject)])

    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let hkType  = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        let hkPredicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date(), options: .strictEndDate)
        
        let options : HKStatisticsOptions  = HKStatisticsOptions.discreteAverage
        
        let hkQuery = HKStatisticsQuery(quantityType: hkType,
                                        quantitySamplePredicate: hkPredicate,
                                        options: options) {
                                            query, result, error in
                                            
                                            if(error != nil) {
                                                print(error.debugDescription);
                                            }
                                            
                                            if let value = result!.averageQuantity()?.doubleValue(for: HKUnit(from: "ms")) {
                                                
                                                DispatchQueue.main.async() {
                                                    
                                                    if value > 0.0 {
                                                        self.hrvLabel.setText("\(Int(value).description)")
                                                    }
                                                }
                                            }
        }
        
        ZBFHealthKit.healthStore.execute(hkQuery)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
