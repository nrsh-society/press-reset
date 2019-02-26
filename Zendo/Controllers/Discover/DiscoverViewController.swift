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

class SubscriptionHeaderTableViewCell: UITableViewCell {
    
    enum SubscriptionStatus: String {
        case end = "your trial has ended"
        case trial =  "days remaining on your free trial"
    }
    
    @IBOutlet weak var textLabelSub: UILabel!
    @IBAction func subscribeAction(_ sender: UIButton) {
        action?()
    }
    
    var isTrial: Bool? = nil {
        didSet {
            if let trial = isTrial, trial {
                if let date = Settings.startTrialDate {
                    let days = date.addingTimeInterval(60*60*24*14).days(from: Date())
                    
                    if days <= 0 {
                        textLabelSub.text = SubscriptionStatus.end.rawValue
                    } else {
                        textLabelSub.text = "\(days + 1) " + SubscriptionStatus.trial.rawValue
                    }
                    
                }
            }
        }
    }
    
    var action: (()->())?
    
}


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
    
    var isNoInternet = false
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
    
    var isTrial: Bool? = nil
    var isSubscription: Bool? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        try? storage?.removeAll()
        //        try? self.storageCodable?.removeAll()
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(onReload), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.register(NoInternetTableViewCell.nib, forCellReuseIdentifier: NoInternetTableViewCell.reuseIdentifierCell)
        
        if let email = Settings.email
        {
            Mixpanel.mainInstance().identify(distinctId: email)
            
            Mixpanel.mainInstance().people.set(properties: ["$email": email])
            
            if let name = Settings.fullName
            {
                Mixpanel.mainInstance().people.set(properties: ["$name": name])
            }
        }
        
        
    }
    
    @IBAction func onNewSession(_ sender: Any) {
        startingSession()
    }
    
    @objc func onReload(_ sender: UIRefreshControl) {
        startConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Mixpanel.mainInstance().time(event: "phone_discover")
        
        startConnection()
        
        Settings.checkSubscriptionAvailability { subscription, trial in
            self.isTrial = trial
            self.isSubscription = subscription
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_discover")
    }
    
    func startConnection()
    {
        
        isNoInternet = false
        
        #if DEBUG
        let urlPath: String = "http://media.zendo.tools/discover.v4.json?v=\(Date().timeIntervalSinceNow)"
        #else
        let urlPath: String = "http://media.zendo.tools/discover.v4.json?v=\(Date().timeIntervalSinceNow)"
        #endif
        
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
                            
                            var contents = [String]()
                            
                            for section in discover.sections {
                                for story in section.stories {
                                    for content in story.content {
                                        if let download = content.download {
                                            contents.append(download)
                                        }
                                    }
                                }
                            }
                            
                            self.downloadVideo(contents)
                        }
                        
                    }
                    
                } catch {
                    
                }
            } else if let error = error {
                if let oldDiscover = try? self.storageCodable?.object(forKey: Discover.key), let discover = oldDiscover {
                    
                    var isAllLoaded = true
                    
                    var contents = [String]()
                    
                    for section in discover.sections {
                        for story in section.stories {
                            for content in story.content {
                                if let download = content.download {
                                    contents.append(download)
                                }
                            }
                        }
                    }
                    
                    for (index, download) in contents.enumerated() {
                        self.storage?.async.entry(forKey: download, completion: { result in
                            switch result {
                            case .error:
                                isAllLoaded = false
                                self.setNoInternetScreen()
                                return
                            case .value( _):
                                if index == contents.count - 1 {
                                    if isAllLoaded {
                                        self.discover = discover
                                        DispatchQueue.main.async {
                                            self.refreshControl.endRefreshing()
                                            self.tableView.reloadData()
                                        }
                                    } else {
                                        self.setNoInternetScreen()
                                    }
                                }
                            }
                        })
                    }
                    
                } else {
                    self.isNoInternet = error.code == -1001 || error.code == -1009
                }
            }
            
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
            
            }.resume()
        
    }
    
    func getHeightCell() -> CGFloat {
        let height = UIScreen.main.bounds.height / 3.0
        
        if sections.count == 1 {
            var countStories = sections[0].stories.count
            if countStories % 2 == 0 {
                countStories = countStories / 2
                return CGFloat(countStories) * height
            } else {
                countStories -= 1
                countStories = countStories / 2
                return (CGFloat(countStories) * height) + height
            }
        }
        return 0.0
    }
    
    func setNoInternetScreen() {
        self.isNoInternet = true
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if let trial = isTrial, let subscription = isSubscription, trial && !subscription  {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: SubscriptionHeaderTableViewCell.reuseIdentifierCell) as! SubscriptionHeaderTableViewCell
            
            cell.isTrial = trial
            cell.action = {
                let vc = SubscriptionViewController.loadFromStoryboard()
                self.present(vc, animated: true)
            }
            
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let trial = isTrial, let subscription = isSubscription, trial && !subscription {
            return 40.0
        }
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return isNoInternet ? tableView.frame.height : (sections.count == 1 ? getHeightCell() : tableView.frame.height / 2.0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isNoInternet ? 1 : sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isNoInternet {
            let cell = tableView.dequeueReusableCell(withIdentifier: NoInternetTableViewCell.reuseIdentifierCell, for: indexPath) as! NoInternetTableViewCell
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscoverTableViewCell.reuseIdentifierCell, for: indexPath) as! DiscoverTableViewCell
            
            if let layout = cell.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                if sections.count == 1 {
                    layout.scrollDirection = .vertical
                    cell.collectionView.isScrollEnabled = false
                } else {
                    layout.scrollDirection = .horizontal
                    cell.collectionView.isScrollEnabled = true
                }
            }
            
            cell.topLabel.text = "  " + sections[indexPath.row].name
            cell.topLabel.isHidden = sections.count == 1
            cell.topSpace.constant = sections.count == 1 ? 0 : 10
            return cell
        }
        
    }
    
}

//MARK: - UICollectionViewDataSource

extension DiscoverViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[collectionView.tag].stories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiscoverCollectionViewCell.reuseIdentifierCell, for: indexPath) as! DiscoverCollectionViewCell
        cell.hero.id = "cellImage" + indexPath.row.description + collectionView.tag.description
        cell.story = sections[collectionView.tag].stories[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        
        dataTask?.cancel()
        
        let story = sections[collectionView.tag].stories[indexPath.row]
        
        var vc : UIViewController?
        
        if story.type == "arena"
        {
            
            let arena = ArenaController.loadFromStoryboard()
            arena.story = story
            
            arena.idHero = "cellImage" + indexPath.row.description + collectionView.tag.description
            vc = arena
            
        }
        else
        {
            let video = VideoViewController.loadFromStoryboard()
            video.idHero = "cellImage" + indexPath.row.description + collectionView.tag.description
            video.story = story
            vc = video
        }
        
        vc?.hero.isEnabled = true
        present(vc!, animated: true, completion: nil)
    }
    
}

//MARK: - UICollectionViewDelegateFlowLayout

extension DiscoverViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let padding: CGFloat = space * 3
        let collectionViewSize = collectionView.frame.size.width - padding
        let collectionViewSizeHeight = sections.count == 1 ? UIScreen.main.bounds.height / 3 : collectionView.frame.size.height - padding
        
        let a: CGFloat = sections.count == 1 ? 2.0 : 2.5
        return CGSize(width: (collectionViewSize/a), height: (collectionViewSizeHeight - space))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let a: CGFloat = sections.count == 1 ? 1 : -5
        
        return UIEdgeInsets(top: space / 2, left: space - a, bottom: space / 2, right: space - a)
    }
    
}
