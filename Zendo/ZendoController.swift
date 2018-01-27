//
//  ViewController.swift
//  Zazen
//
//  Created by Douglas Purdy on 12/27/17.
//  Copyright © 2017 zenbf. All rights reserved.
//

import UIKit
import HealthKit

class ZendoController: UITableViewController {
    
    private var _sampleCount = 0;
    private var _samples = nil as [HKSample]?;
    private let _healthStore = HKHealthStore();
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let hkType = HKObjectType.workoutType();
        
        let hkPredicate = HKQuery.predicateForWorkouts(with: .mindAndBody);
        
        let hkQuery = HKSampleQuery.init(sampleType: hkType, predicate: hkPredicate, limit: HealthKit.HKObjectQueryNoLimit, sortDescriptors: nil, resultsHandler: {query,results,error in
            
            if(error != nil ) { print(error!); } else {
                
                DispatchQueue.main.async() {
                    
                    self._sampleCount = results!.count;
                    self._samples = results;
                    
                    self.tableView.reloadData();
                    
                };
            }
            
        });
        
        _healthStore.execute(hkQuery)
        
        /*
         
         let hkType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
         let hkSource = HKSource.default();
         
         /let hkPredicate = HKQuery.predicateForObjects(from: hkSource);
         
         */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _sampleCount;
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let key = "zendoCell";
        
        let cell = tableView.dequeueReusableCell(withIdentifier: key, for: indexPath);
        
        let sample = _samples![indexPath.row];
        
        let workout = sample as! HKWorkout;
        
        let dateFormatter = DateFormatter();

        dateFormatter.timeZone = TimeZone.autoupdatingCurrent;
        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY.MM.dd")
        
        let localDate = dateFormatter.string(from: sample.endDate)
        
        dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
        let localTime = dateFormatter.string(from: sample.endDate)
        
        //let text = localDate.description + " : " + Int((workout.duration / 60).rounded()).description;
        
        cell.textLabel?.text = Int((workout.duration / 60).rounded()).description;
        
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 33.0);
        
        cell.detailTextLabel?.text = localDate.description + " " + localTime.description;
        
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
        
        let alert = UIAlertController(title: "New Session", message: "Continue on Watch", preferredStyle: .alert);
        
        let ok = UIAlertAction(title: "OK", style: .default) { action in }
        
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: {
            
        });
    }
    
    
}
