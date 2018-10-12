//
//  NavigationControllerWelcome.swift
//  Zendo
//
//  Created by Anton Pavlov on 12/10/2018.
//  Copyright © 2018 zenbf. All rights reserved.
//

import UIKit

class NavigationControllerWelcome: UINavigationController {

    static func loadFromStoryboard() -> NavigationControllerWelcome {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NavigationControllerWelcome") as! NavigationControllerWelcome
    }
   
}
