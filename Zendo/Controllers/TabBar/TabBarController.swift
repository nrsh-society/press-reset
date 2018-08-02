//
//  TabBarViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 02/08/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit


class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for item in tabBar.items! {
            item.image = item.selectedImage!.with(color: UIColor.zenLightGreen).withRenderingMode(.alwaysOriginal)
        }
        
    }
    
}
