//
//  DiscoverCollectionViewCell.swift
//  Zendo
//
//  Created by Anton Pavlov on 18/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

class DiscoverCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var discoverImageView: UIImageView!
    
    var story: Story! {
        didSet {
            titleLabel.text = story.title
            if let thumbnailUrl = story.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                discoverImageView.setImage(from: url) { _, _ in
                    self.layoutIfNeeded()
                    self.addGradientLayer()
                }
            }
        }
    }
    
    func addGradientLayer() {
        
        var isAdd = true
        
        if let sublayers = discoverImageView.layer.sublayers {
            for i in 0..<sublayers.count {
                let imageLayer = sublayers[i]
                
                if imageLayer is CAGradientLayer {
                    isAdd = false
                }
            }
        }
        
        
        if isAdd {
            let gradient = CAGradientLayer()
            gradient.frame = bounds
            gradient.colors = [UIColor(red: 0.24, green: 0.29, blue: 0.28, alpha: 0.5).cgColor,
                               UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0).cgColor]
            gradient.locations = [0, 1]
            gradient.cornerRadius = 10.0
            gradient.masksToBounds = true
            gradient.startPoint = CGPoint(x: 0.5, y: 1.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 0.5)
            
            discoverImageView.layer.addSublayer(gradient)
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        discoverImageView.layer.cornerRadius = 10.0
        discoverImageView.layer.masksToBounds = true
    }
    

}
