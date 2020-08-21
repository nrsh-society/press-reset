//
//  ProgressView.swift
//  Zendo
//
//  Created by Doug Purdy on 01/03/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import Charts

class ProgressView: UIView {
    
    @IBOutlet weak var minutes: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    
    @IBOutlet weak var meditator: UILabel!
    @IBOutlet weak var meditatorLabel: UILabel!
    
    @IBOutlet weak var cause: UILabel!
    @IBOutlet weak var causeLabel: UILabel!
    
    @IBOutlet weak var sponsorLabel: UILabel!
    @IBOutlet weak var sponsor: UILabel!
    
    @IBOutlet weak var creatorLabel: UILabel!
    @IBOutlet weak var creator: UILabel!
    
    @IBOutlet weak var donatorLabel: UILabel!
    @IBOutlet weak var donator: UILabel!
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 20.0
        backgroundColor = UIColor(red:0.06, green:0.15, blue:0.13, alpha:0.3)
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor(red:0, green:0, blue:0, alpha:0.5).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 20
    }
    
    func update(minutes: String, meditator: String, cause: String, sponsor: String, creator: String, donator: String)
    {
        self.minutes.text = minutes
        self.meditator.text = meditator
        self.cause.text = cause
        self.sponsor.text = sponsor
        self.creator.text = creator
        self.donator.text = donator
    }
    
}
