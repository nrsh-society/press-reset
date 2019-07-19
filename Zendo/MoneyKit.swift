//
//  MoneyKit.swift
//
//  Created by Douglas Purdy on 7/18/19.
//  Copyright © 2019 Humanity. All rights reserved.
//

import Foundation

class MoneyKit
{
    struct Payment
    {
        var source_address : String
        var source_amount : Amount
        var destination_address : String
        var destination_amount : Amount
    }

    struct Amount
    {
        var value : Int
        var currency : String
    }
    
    static func pay(_ payment : Payment)
    {
        //#todo: call xrp-api here
    }
}
