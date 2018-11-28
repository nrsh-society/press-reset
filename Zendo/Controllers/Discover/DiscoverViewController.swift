//
//  DiscoverViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit
import Hero
import AVFoundation
import SwiftyJSON
import HealthKit
import Mixpanel
import Cache


class DiscoverTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    
    var collectionViewOffset: CGFloat {
        get {
            return collectionView.contentOffset.x
        }
        set {
            collectionView.contentOffset.x = newValue
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        collectionView.register(DiscoverCollectionViewCell.nib, forCellWithReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell)
        
    }
    
    func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>(dataSourceDelegate: D, forRow row: Int) {
        
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }
    
}

class DiscoverViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var refreshControl = UIRefreshControl()
    
    let healthStore = ZBFHealthKit.healthStore
    let space: CGFloat = 9
    
    var storedOffsets = [Int: CGFloat]()
    var discover: Discover?
    var sections: [Section] {
        return discover?.sections ?? []
    }
    
    var dataTask: URLSessionDataTask?
    
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    lazy var storageCodable: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: Discover.self))
    }()
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        try? storage?.removeAll()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @IBAction func onNewSession(_ sender: Any) {
        let startingSessions = StartingSessionViewController()
        startingSessions.modalPresentationStyle = .overFullScreen
        startingSessions.modalTransitionStyle = .crossDissolve
        present(startingSessions, animated: true, completion: nil)
    }
    
    @objc func onReload(_ sender: UIRefreshControl) {
        startConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        tableView.contentOffset = CGPoint(x: 0.0, y: -refreshControl.frame.size.height)
        //        refreshControl.beginRefreshing()
        
        startConnection()
    }
    
    func startConnection() {
        
        let urlPath: String = "http://media.zendo.tools/discover.json?v=\(Date().timeIntervalSinceNow)"
        
        URLSession.shared.dataTask(with: URL(string: urlPath)!) { data, response, error -> Void in
            
            if let data = data, error == nil {
                do {
                    let json = try JSON(data: data)
                    self.discover = Discover(json)
                    
                    DispatchQueue.global(qos: .background).async {
                        
                        guard let discover = self.discover else { return }
                        
                        if let oldDiscover = try? self.storageCodable?.object(forKey: Discover.key) {
                            
                            guard let oldDiscover = oldDiscover else { return }
                            
                            var oldContent = [String]()
                            var newContent = [String]()
                            
                            for section in oldDiscover.sections {
                                for story in section.stories {
                                    for content in story.content {
                                        if let download = content.download {
                                            oldContent.append(download)
                                        }
                                    }
                                }
                            }
                            
                            for section in discover.sections {
                                for story in section.stories {
                                    for content in story.content {
                                        if let download = content.download {
                                            newContent.append(download)
                                        }
                                    }
                                }
                            }
                            
                            for old in oldContent {
                                var isRemove = true
                                for new in newContent {
                                    if old == new {
                                        isRemove = false
                                    }
                                }
                                if isRemove {
                                    try? self.storage?.removeObject(forKey: old)
                                }
                            }
                            
                            try? self.storageCodable?.setObject(discover, forKey: Discover.key)
                            
                            self.downloadVideo(newContent)
                            
                        } else if let discover = self.discover {
                            try? self.storageCodable?.setObject(discover, forKey: Discover.key)
                        }
                        
                    }
                    
                } catch {
                    
                }
            }
            
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
            
            }.resume()
        
    }
    
    func downloadVideo(_ contents: [String], index: Int = 0) {
        for (i, content) in contents.enumerated() {
            
            if index > i {
                continue
            }
            
            if let url = URL(string: content) {
                
                self.storage?.async.entry(forKey: url.absoluteString, completion: { result in
                    
                    switch result {
                    case .error:
                        var request = URLRequest(url: url)
                        request.httpMethod = "GET"
                        
                        self.dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
                            if let data = data, error == nil {
                                self.storage?.async.setObject(data, forKey: url.absoluteString, completion: { _ in })
                                
                                self.downloadVideo(contents, index: i + 1)
                            }
                        }
                        
                        self.dataTask?.resume()
                    case .value( _):
                        self.downloadVideo(contents, index: i + 1)
                    }
                    
                })
                
                if i == index {
                    break
                }
            }
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    
}

extension DiscoverViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? DiscoverTableViewCell else { return }
        
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? DiscoverTableViewCell else { return }
        
        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }
}

extension DiscoverViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / 2.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverTableViewCell.reuseIdentifierCell, for: indexPath) as! DiscoverTableViewCell
        cell.topLabel.text = "  " + sections[indexPath.row].name
        cell.topLabel.isHidden = sections.count == 1
        cell.topSpace.constant = sections.count == 1 ? 0 : 10
        return cell
    }
    
}

//MARK: - UICollectionViewDataSource

extension DiscoverViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[collectionView.tag].stories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell, for: indexPath) as! DiscoverCollectionViewCell
        cell.hero.id = "cellImage" + indexPath.row.description
        cell.story = sections[collectionView.tag].stories[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {        
        let vc = VideoViewController.loadFromStoryboard()
        vc.idHero = "cellImage" + indexPath.row.description
        vc.hero.isEnabled = true
        vc.story = sections[collectionView.tag].stories[indexPath.row]
        dataTask?.cancel()
        present(vc, animated: true, completion: nil)
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout

extension DiscoverViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = space * 3
        let collectionViewSize = collectionView.frame.size.width - padding
        let collectionViewSizeHeight = collectionView.frame.size.height - padding
        
        let a: CGFloat = sections.count == 1 ? 2.0 : 2.5
        return CGSize(width: (collectionViewSize/a), height: (collectionViewSizeHeight - space))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let a: CGFloat = sections.count == 1 ? 0 : 5
        
        return UIEdgeInsets(top: space / 2, left: space + a, bottom: space / 2, right: space + a)
    }
    
}
