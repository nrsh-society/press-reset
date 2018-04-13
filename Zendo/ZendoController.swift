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
    
    private var _samples = nil as [HKSample]?
    private let _healthStore = ZBFHealthKit.healthStore
    private var currentWorkout : HKWorkout?
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
      
        let hkType = HKObjectType.workoutType();
        let hkPredicate = HKQuery.predicateForObjects(from: HKSource.default())
        
        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
        
        let hkQuery = HKSampleQuery.init(sampleType: hkType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: {query,results,error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.async() {

                    self._samples = results
                    
                    self.tableView.reloadData();
                    
                };
            }
            
        });
        
        _healthStore.execute(hkQuery)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sample = _samples![indexPath.row];
        
        currentWorkout = (sample as! HKWorkout);
                
        let details = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "zazen-controller") as! ZazenController

        details.workout = currentWorkout
        
        present(details, animated: true, completion: {});
        
    }
    
    public override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let sample = _samples![indexPath.row];
        
        currentWorkout = (sample as! HKWorkout);
    }

    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = _samples?.count {
            return count
        } else { return 0 }
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let key = "zendoCell";
        
        let cell = tableView.dequeueReusableCell(withIdentifier: key, for: indexPath);
        
        let sample = _samples![indexPath.row];
        
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
        
        _healthStore.startWatchApp(with: configuration) { (success, error) in
            guard success else { print (error.debugDescription); return }
           
        }
        
        let alert = UIAlertController(title: "Zendo", message: "Continue on Watch", preferredStyle: .alert);
        
        let ok = UIAlertAction(title: "OK", style: .default) { action in }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: {
            
        });
    }
    
    @IBAction func buddhaClick(_ sender: Any) {
        
        let buddhaController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "buddha-controller") as! BuddhaController
        
        present(buddhaController, animated: true, completion: {});
    }
    
    @IBAction func sanghaClick(_ sender: Any) {
        
        let sanghaController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sangha-controller") as! SanghaController
        
        present(sanghaController, animated: true, completion: {});
        
    }
    
    @IBAction func dharmaClick(_ sender: Any) {
        
        let dharmaController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "dharma-controller") as! DharmaController
        
        present(dharmaController, animated: true, completion: {});
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
