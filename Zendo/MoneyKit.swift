//
//  MoneyKit.swift
//
//  Created by Douglas Purdy on 7/18/19.
//  Copyright © 2019 Humanity. All rights reserved.
//

import Foundation

class MoneyKit
{
    static var apiKey = "2b22b5b518d52bed1c8202f0ed9e8ddb"
    static var moneyService = "http://localhost:3000/v1/payments/"
    
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
    
    struct PaymentMessage
    {
        var payment : Payment
        var submit : Bool = true
    }
    
    static func pay(_ payment : Payment)
    {
        var request = URLRequest(url: URL(string: moneyService)!)
        
        let paymentMessage = PaymentMessage(payment: payment, submit: true)
        
        request.httpMethod = "POST"
        
        if let json = try? JSONSerialization.data(withJSONObject: paymentMessage, options: [])
        {
            request.httpBody = json

            URLSession.shared.dataTask(with: request)
            {
                data, response, error in
            
                if let data = data, error == nil
                {
                    print(data)
                }
                else
                {
                    print(error.debugDescription)
                }
            }
        }
    }
}
