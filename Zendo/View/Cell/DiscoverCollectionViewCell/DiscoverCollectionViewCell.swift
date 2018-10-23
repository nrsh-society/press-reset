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
            if let thumbnailUrl = story.thumbnailUrl {
                discoverImageView.imageFromUrl(urlString: thumbnailUrl)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let _ = story.thumbnailUrl {
            shadowView()
        }
        
        discoverImageView.layer.cornerRadius = 10.0
        discoverImageView.layer.masksToBounds = true
    }
    

}
