//
//  ViewController.swift
//  zendō arena
//
//  Created by Douglas Purdy on 2/5/19.
//  Copyright © 2019 Zendo Tools. All rights reserved.
//

import UIKit
import Hero
import SpriteKit
import Firebase
import FirebaseDatabase
import HealthKit
import AVKit
import Mixpanel
import Cache
import AvatarCapture
import Movesense
import SwiftyJSON


class Player
{
    var id : String
    var email : String?
    var duration : Int = 0
    var samples = [Double]()
    var startDate = Date()
    
    init(id: String)
    {
        self.id = id
    }
    
    func getProfileUrl() -> String
    {
        return "\(self.id)"
    }
    
    func getMeditativeState() -> Bool
    {
        var retval = false
        
        if (self.samples.count > 2)
        {
            let min = self.samples.min()
            let max = self.samples.max()
            
            let range = max! - min!
            
            if range > 2
            {
                retval = true
            }
        }
        
        return retval
    }
    
    func getProgress() -> String
    {
        var progress = "false/1"
        
        let startDate = self.startDate
        
        let mins = abs(startDate.minutes(from: Date()))
        
        if(mins > 0)
        {
            progress = "\(self.getMeditativeState())/\(mins)"
        }
        
        return progress
    }
    
    func getUpdate() -> [String : String]
    {
        return [ "progress" : self.getProgress()]
    }
    
    func getHRV() -> Double
    {
        return self.standardDeviation(self.samples)
    }
    
    func standardDeviation(_ arr : [Double]) -> Double
    {
        let rrIntervals = arr.map
        {
            (beat) -> Double in
            
            return 1000 / beat
        }
        
        let length = Double(rrIntervals.count)
        
        let avg = rrIntervals.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = rrIntervals.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
}

class MovesensePlayerCell : UITableViewCell
{
    @IBOutlet weak var textField: UITextField!
}

class GroupController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate
{
    let avatarCaptureController = AvatarCaptureController()
    let movesenseService = MovesenseService.Instance
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
    
    var players = [String : Player]()
    var story : Story!
    var idHero = ""
    var panGR : UIPanGestureRecognizer!
    var chartHR = [String: Int]()
    var scene : SKScene?
    var profileImage : UIImage?
    var lastUpdate = NSMutableDictionary()
    
    @IBOutlet weak var spriteView: SKView!
    {
        didSet {
            spriteView.hero.id = idHero
        }
    }
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var avatarView: UIView!
    
    @IBOutlet weak var arenaView: ArenaView! {
        didSet {

            arenaView.isHidden = true
            arenaView.alpha = 1.0
            arenaView.hrv.text = "--"
            arenaView.time.text = "--"
        }
    }

    @IBOutlet weak var playerTableView: UITableView!
    {
        didSet {
            playerTableView.delegate = self
            playerTableView.dataSource = self
        }
    }
    
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()
    
    static func loadFromStoryboard() -> GroupController
    {
       let controller = UIStoryboard(name: "GroupController", bundle: nil).instantiateViewController(withIdentifier: "GroupController") as! GroupController

        return controller
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        try? storage?.removeAll()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        let player = (Array(players.values)[textField.tag])

        player.email = textField.text
        
        players[player.id] = player
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! MovesensePlayerCell
        
        let row = indexPath.row
        let player = Array(players.values)[row]
    
        cell.textField.tag = row
        cell.textField.delegate = self
        
        if let email = player.email
        {
            cell.textField.text = email
        }
        else
        {
            cell.textField.text = player.id
            
        }
    
        cell.textField.backgroundColor = UIColor.clear
        cell.textField.textColor = UIColor.white
        cell.textField.layer.borderColor = UIColor.zenLightGreen.cgColor
        cell.textField.layer.borderWidth = 1.0
        cell.textField.layer.cornerRadius = 8.0
        cell.textField.layer.masksToBounds = true
        //cell.textLabel?.text = player.email
        //cell.textLabel?.textColor = UIColor.white
        cell.imageView?.image = UIImage(named: "shobogenzo")
        /*
         #todo: when profile photo uploading works
         
         let url = URL(string: player.getProfileUrl())
         cell.imageView?.setImage(from : url) { _, _ in }
         */
        return cell
    }
    
    func setBackground() {
        if let story = story, let thumbnailUrl = story.thumbnailUrl, let url = URL(string: thumbnailUrl) {
            UIImage.setImage(from: url) { image in
                DispatchQueue.main.async {
                    self.spriteView.addBackground(image: image, isLayer: false, isReplase: false)
                }
            }
        }
    }
    
    func removeBackground()
    {
        if let viewWithTag = self.view.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    func startBackgroundContent(story : Story, completion: @escaping (AVPlayerItem) -> Void)
    {
        var playerItem: AVPlayerItem?
        
        let streamString = story.content[0].stream
        let downloadString = story.content[0].download
        
        var downloadUrl : URL?
        var streamUrl : URL?
        
        if let urlString = downloadString, let url = URL(string: urlString)
        {
            downloadUrl = url
        }
        
        if let urlString = streamString, let url = URL(string: urlString)
        {
            streamUrl = url
        }
        
        storage?.async.entry(forKey: downloadUrl?.absoluteString ?? "", completion:
        {
            result in
            
            switch result
            {
                case .value(let entry):
                
                    if var path = entry.filePath
                    {
                        if path.first == "/"
                        {
                            path.removeFirst()
                        }
                    
                        let url = URL(fileURLWithPath: path)
                    
                        playerItem = AVPlayerItem(url: url)
                    }
            
                default:
                    
                    if let url = streamUrl
                    {
                        playerItem = AVPlayerItem(url: url)
                    }
                    else
                    {
                        playerItem = AVPlayerItem(url: downloadUrl!)
                    }
            }
            
            completion(playerItem!)
            
        })
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "group_train", properties: ["name": story.title])
        
        NotificationCenter.default.removeObserver(self)
        
        spriteView.scene?.removeAllChildren()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        self.spriteView.presentScene(nil)
        self.scene = nil
        
        self.players.removeAll()
    }
    
    func setupConnectButton()
    {
        self.connectButton.addTarget(self, action: #selector(connectAppleWatch), for: .primaryActionTriggered)
        
        self.connectButton.layer.borderColor = UIColor.white.cgColor
        self.connectButton.layer.borderWidth = 1.0
        self.connectButton.layer.cornerRadius = 10.0
        self.connectButton.backgroundColor = UIColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
        self.connectButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.connectButton.layer.shadowColor = UIColor(red:0, green:0, blue:0, alpha:0.5).cgColor
        self.connectButton.layer.shadowOpacity = 1
        self.connectButton.layer.shadowRadius = 20
    }
    
    func setupSensorNotifications()
    {
       NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sample),
                                               name: .sample,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.progress),
                                               name: .progress,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startSession),
                                               name: .startSession,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(endSession),
                                               name: .endSession,
                                               object: nil)
 
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setBackground()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        Mixpanel.mainInstance().time(event: "phone_group")
        
        setupSensorNotifications()
        
        do {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        
        self.spriteView.presentScene(self.setupScene())
        
        avatarCaptureController.delegate = self
        avatarView.addSubview((avatarCaptureController.view)!)
        
        self.movesenseService.setHandlers(
        deviceConnected:
        {
            (serial: String) ->() in
            
            self.updateConnected(serial)
            
        },
        deviceDisconnected:
        {
            (serial: String) ->() in
            
            self.updateDisconnected(serial)
        },
        bleOnOff:
        {
            _ in
                
            self.updatebleOnOff()
        })
        
        self.playerTableView.setNeedsLayout()
        
        let _ = self.movesenseService.startScan(
        {
            (device : MovesenseDevice) -> () in
            
            self.peripheralFound(device: device)
            
        })
        
        self.startSession()
        
    }
    
    @objc func avatarViewClicked()
    {
        avatarCaptureController.startCapture()
    }
    
    @objc func connectAppleWatch()
    {
        //avatarCaptureController.startCapture()
        
        let startingSessions = StartingSessionViewController()
        
        startingSessions.modalPresentationStyle = .overFullScreen
        
        startingSessions.modalTransitionStyle = .crossDissolve
        
        self.present(startingSessions, animated: true)
    }
    
    @objc func startSession()
    {
        if(Settings.isSensorConnected)
        {
            Mixpanel.mainInstance().time(event: "phone_group_session")
            
            if let image = self.profileImage
            {
                Cloud.createPlayer(email: Settings.email!, image: image)
            }
            
            self.lastUpdate["progress"] = "false/1"
            
            Cloud.updatePlayer(email: Settings.email!, update: self.lastUpdate)
            
            self.players.forEach
            {
                (key: String, value: Player) in
                
                if let email = value.email
                {
                    Cloud.updatePlayer(email: email, update: value.getUpdate())
                }
                else
                {
                    Cloud.updatePlayer(email: value.id, update: value.getUpdate())
                }
            }
            
            DispatchQueue.main.async
            {
                UIView.animate(withDuration: 0.5)
                {
                    self.arenaView.isHidden = false
                    self.connectButton.isHidden = true
                    self.avatarView.isHidden = false
                }
            }
        }
    }
    
    @objc func endSession()
    {
        Mixpanel.mainInstance().track(event: "phone_group_session",
                                          properties: ["name": self.story.title])
        
        Cloud.removePlayers()
        
        Settings.isSensorConnected = false
        
        DispatchQueue.main.async
        {
            UIView.animate(withDuration: 0.5)
            {
                    self.arenaView.isHidden = true
                    self.connectButton.isHidden = false
                
                    self.arenaView.hrv.text = "--"
                    self.arenaView.time.text = "--"
                    self.arenaView.setChart([])
                }
            }
        }
    
    @objc func progress(notification: NSNotification)
    {
        if let progress = notification.object as? String
        {
            self.lastUpdate["progress"] = progress
            
            Cloud.updatePlayer(email: Settings.email!, update: self.lastUpdate)
            
            self.donate()
            
            self.players.forEach
            {
                (key: String, value: Player) in
                
                if let email = value.email
                {
                    Cloud.updatePlayer(email: email, update: value.getUpdate())
                }
                else
                {
                    Cloud.updatePlayer(email: value.id, update: value.getUpdate())
                }
                
                self.donate()
                
                value.samples.removeAll()
            }
        }
    }
    
    func donate()
    {
        if let address = Settings.ilpAddress
        {
            let payment = MoneyKit.Payment(source_address: address, source_amount: MoneyKit.Amount(value: 10, currency: "XRP"), destination_address: story.beneficiaryPaymentAddress!, destination_amount: MoneyKit.Amount(value: 10, currency: "XRP"))
                
            MoneyKit.pay(payment)
        }
    }
    
    @objc func sample(notification: NSNotification)
    {
        if let sample = notification.object as? [String : Any]
        {
            let raw_hrv = sample["sdnn"] as! String
            let double_hrv = Double(raw_hrv)!.rounded()
            let text_hrv = Int(double_hrv.rounded()).description
            
            let raw_hr = sample["heart"] as! String
            let double_hr = (Double(raw_hr)! * 60).rounded()
            let int_hr = Int(double_hr)
            let text_hr = int_hr.description
    
            DispatchQueue.main.async
            {
                self.arenaView.hrv.text = text_hrv
                
                self.arenaView.time.text = text_hr
                
                self.chartHR[String(Date().timeIntervalSince1970)] = int_hr
            
                let chartHR = self.chartHR.sorted(by: <)

                self.arenaView.setChart(chartHR)
            }
        }
    }
    
    func setupScene() -> SKScene
    {
        spriteView.frame = UIScreen.main.bounds
        spriteView.contentMode = .scaleAspectFill
        
        let scene = SKScene(size: (spriteView.frame.size))
        
        scene.scaleMode = .aspectFill
        
        spriteView.allowsTransparency = true
        
        self.startBackgroundContent(story: story, completion:
        {
            item in
            
            DispatchQueue.main.async
            {
                let videoPlayer = AVPlayer(playerItem: item)
                
                let video = SKVideoNode(avPlayer: videoPlayer)
                    
                video.zPosition = 1.0
                video.size = scene.frame.size
                video.position = scene.position
                video.anchorPoint = scene.anchorPoint
                video.play()
                scene.addChild(video)
                
                self.removeBackground()
                    
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                           object: videoPlayer.currentItem, queue: nil)
                    {
                       notification in
                        
                        DispatchQueue.main.async
                        {
                            videoPlayer.seek(to: kCMTimeZero)
                            videoPlayer.play()
                        }
                        
                    }
                }
            
        })
    
        panGR = UIPanGestureRecognizer(target: self, action: #selector(pan))
        spriteView.addGestureRecognizer(panGR)
        
        setupConnectButton()
        
        return scene
        
    }
    
    @objc func pan()
    {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / view.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: spriteView)
        default:
            
             Hero.shared.finish()
            
        }

    }
    
    func peripheralFound(device:MovesenseDevice){
        
        print("movesense found")
        
        print("There are \(self.movesenseService.getDeviceCount()) devices")
        
        self.movesenseService.connectDevice(device.serial)
        
        print("Device: \(device.serial) just connected")
        
        let player = Player(id: device.serial)
        
        self.players[device.serial] = player
        
        self.playerTableView.reloadData()
    }
    
    func updateConnected(_ serial: String)
    {
        print("movesense connected: \(serial)")
    
        self.movesenseService.subscribe(serial, path: Movesense.HR_PATH, parameters: [:], onNotify:
        {
            response in self.handleData(response, serial: serial)
                
        })
        { _,_,_  in }
    }
    
    func updateDisconnected(_ serial: String)
    {
        print("movesense Disconnected")
        
        if let player = (self.players[serial])
        {
            self.players.removeValue(forKey: player.id)
            Cloud.removePlayer(email: player.email!)
        }
        
    }
    
    func updatebleOnOff(){
        print("Bluetooth toggled")
    }
    
    func handleData(_ response: MovesenseResponse, serial: String)
    {
        if(Settings.isSensorConnected)
        {
            let json = JSON(parseJSON: response.content)
        
            if json["rrData"][0].number != nil
            {
                let rr = json["rrData"][0].doubleValue
                
                let hr = 1000/rr
                
                print("device: \(serial) Heart Rate: \(String(hr))")
                
                if let player = (self.players[serial])
                {
                    player.samples.append(hr * 60)
                }
                
            }
        }
    }

}

extension GroupController: AvatarCaptureControllerDelegate
{
    func imageSelected(image: UIImage)
    {
        print("image Selected")
        
        //self.profileImage = image
        
    }
    
    func imageSelectionCancelled() {
        print("image selection cancelled")
    }
}
