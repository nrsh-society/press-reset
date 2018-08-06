//
//  Cell+ReuseIdentifier.swift
//  Finance
//
//  Created by Anton Pavlov on 20/11/2017.
//  Copyright © 2017 Anton Pavlov. All rights reserved.
//

import UIKit

extension UITableViewCell {
    static var reuseIdentifierCell: String{
        return String(describing: classForCoder())
    }
}

extension UICollectionReusableView {
    static var reuseIdentifierCell: String{
        return String(describing: classForCoder())
    }
}
