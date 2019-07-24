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
    static var moneyService = "http://10.20.26.229:3000/v1/payments/"
    
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
        
        //let paymentMessage = PaymentMessage(payment: payment, submit: true)
        
        request.httpMethod = "POST"
        
        request.addValue("Bearer 2b22b5b518d52bed1c8202f0ed9e8ddb", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let paymentMessage = "{ 'payment': { 'source_address': '\(payment.source_address)', 'source_amount': { 'value': '\(payment.source_amount.value)', 'currency': '\(payment.source_amount.currency)' }, 'destination_address': '\(payment.destination_address)', 'destination_amount': { 'value': '\(payment.source_amount.value)', 'currency': '\(payment.source_amount.currency)' } }, 'submit': true }"
        
        print(paymentMessage)
        
       // if let json = try? JSONSerialization.data(withJSONObject: paymentMessage, options: [])
        //{
            request.httpBody = paymentMessage.data(using: .utf8)

        var dataTask = URLSession.shared.dataTask(with: request)
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
        
        dataTask.resume()
        //}
    }
}
