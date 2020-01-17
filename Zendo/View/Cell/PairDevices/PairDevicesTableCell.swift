//
//  PairDevicesTableCell.swift
//  Zendo
//
//  Created by Boris Sedov on 09.01.2020.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit

class PairDevicesTableCell: UITableViewCell {

    @IBOutlet weak var imageCheck: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mainView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        mainView.layer.cornerRadius = 10.0
        mainView.layer.borderWidth = 1
        mainView.layer.borderColor = UIColor.zenYellowBorder.cgColor
    }
    
}
