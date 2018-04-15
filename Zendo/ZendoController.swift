//
//  ViewController.swift
//  Zazen
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import UIKit
import HealthKit

class ZendoController: UITableViewController  {
    
    var currentWorkout : HKWorkout?
    var samples = nil as [HKSample]?
    let hkType = HKObjectType.workoutType();
    let healthStore = ZBFHealthKit.healthStore
    let hkPredicate = HKQuery.predicateForObjects(from: HKSource.default())
    
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func populateTable() {
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        
        let hkQuery = HKSampleQuery.init(sampleType: hkType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query,results,error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.async() {
                    
                    self.samples = results
                    
                    self.tableView.reloadData();
                    
                };
            }
            
        });
        
        healthStore.execute(hkQuery)
        
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        populateTable()
        
        let oQuery = HKObserverQuery.init(sampleType: hkType, predicate:hkPredicate) {
            
            query,results,error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.async() {
                    
                    self.populateTable()
                    
                };
            }
        }
        
        healthStore.execute(oQuery)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sample = samples![indexPath.row];
        
        currentWorkout = (sample as! HKWorkout);
        
        let details = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "zazen-controller") as! ZazenController
        
        details.workout = currentWorkout
        
        present(details, animated: true, completion: {});
        
    }
    
    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let sample = samples![indexPath.row];
        
        currentWorkout = (sample as! HKWorkout);
    }
    
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let count = samples?.count {
            return count
        } else {
            return 0
            
        }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let key = "zendoCell";
        
        let cell = tableView.dequeueReusableCell(withIdentifier: key, for: indexPath);
        
        let sample = samples![indexPath.row];
        
        let workout = (sample as! HKWorkout);
        
        ZBFHealthKit.populateCell(workout: workout, cell: cell);
        
        return cell;
        
    }
    
    @IBAction func onReload(_ sender: UIRefreshControl) {
        
        self.viewDidLoad();
        
        sender.endRefreshing()
    }
    
    @IBAction func onNewSession(_ sender: Any) {
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        healthStore.startWatchApp(with: configuration) { (success, error) in
            guard success else { print (error.debugDescription); return }
            
        }
        
        let alert = UIAlertController(title: "Zendo", message: "Continue on Watch", preferredStyle: .alert);
        
        let ok = UIAlertAction(title: "OK", style: .default) { action in }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: {
            
            self.populateTable()
            
        });
    }
    
    @IBAction func buddhaClick(_ sender: Any) {
        showController("buddha-controller")
    }
    
    @IBAction func sanghaClick(_ sender: Any) {
        showController("sangha-controller")
    }
    
    @IBAction func dharmaClick(_ sender: Any) {
        showController("dharma-controller")
    }
    
    func showController(_ named: String) {
        
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: named)
        
        present(controller, animated: true, completion: {});
        
    }
    
    @IBAction func actionClick(_ sender: Any) {
        exportAll()
    }
    
    func exportAll() {
        
        var samples = [[String:Any]]()
        
        let hkPredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        
        
        let hkQuery = HKSampleQuery.init(sampleType: mindfulSessionType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query, results, error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.sync() {
                    
                    samples = results!.map { dictionary in
                        var dict: [String: String] = [:]
                        dictionary.metadata!.forEach { (key, value) in dict[key] = "\(value)" }
                        return dict
                    }
                    
                    let fileName = "zazen.json"
                    let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                    
                    let outputStream = OutputStream(url: path!, append: false)
                    
                    outputStream?.open()
                    
                    JSONSerialization.writeJSONObject(
                        samples,
                        to: outputStream!,
                        options: JSONSerialization.WritingOptions.prettyPrinted,
                        error: nil)
                    
                    outputStream?.close()
                    
                    let vc = UIActivityViewController(activityItems: [path as Any], applicationActivities: [])
                    
                    vc.excludedActivityTypes = [
                        UIActivityType.assignToContact,
                        UIActivityType.saveToCameraRoll,
                        UIActivityType.postToFlickr,
                        UIActivityType.postToVimeo,
                        UIActivityType.postToTencentWeibo,
                        UIActivityType.postToTwitter,
                        UIActivityType.postToFacebook,
                        UIActivityType.openInIBooks
                    ]
                    
                    self.present(vc, animated: true, completion: nil)
                    
                };
            }
            
        });
        
        HKHealthStore().execute(hkQuery)
        
    }
    
}
