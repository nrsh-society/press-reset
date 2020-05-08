//
//  LabController.swift
//  Zendo
//
//  Created by Douglas Purdy on 5/8/20.
//  Copyright © 2020 zenbf. All rights reserved.
//

import UIKit

class LabController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()

    }
    
    static func loadFromStoryboard() -> LabController
    {
        let controller = UIStoryboard(name: "LabController", bundle: nil).instantiateViewController(withIdentifier: "LabController") as! LabController
        
        return controller
        
    }
}
