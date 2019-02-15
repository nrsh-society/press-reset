//
//  SubscriptionViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 14/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import StoreKit

class SubscriptionViewController: UIViewController {
    
    var PRODUCT_ID = "ZendoPurchase1" //Get it from iTunes connect
    
    var productID = ""
    var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var subButtonView: UIView! {
        didSet {
            let gr = UITapGestureRecognizer(target: self, action: #selector(subscription))
            subButtonView.addGestureRecognizer(gr)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        priceLabel.text = ""
        
        fetchAvailableProducts()
        
    }
    
    static func loadFromStoryboard() -> SubscriptionViewController {
        let storyboard =  UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "SubscriptionViewController") as! SubscriptionViewController
        return storyboard
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        subButtonView.layoutIfNeeded()
        subButtonView.shadowView()
    }
    
    @objc func subscription() {
        if !iapProducts.isEmpty {
            purchaseProduct(product: iapProducts[0])
        }
    }
    
    @IBAction func restoreOnClick(_ sender: UIButton) {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func purchaseProduct(product: SKProduct) {
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            print("Product to Purchase: \(product.productIdentifier)")
            productID = product.productIdentifier
        } else {
            self.present(showAlertContrller(title: "Oops!", message: "Purchases are disabled in your device!"), animated: true, completion: nil)
        }
    }
    
    func showAlertContrller(title: String, message: String, handler: (() -> ())? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { action in
            handler?()
        }
        alertController.addAction(alertAction)
        return alertController
    }
    
    func canMakePurchases() -> Bool { return SKPaymentQueue.canMakePayments() }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func fetchAvailableProducts() {
        let productIdentifiers = NSSet(objects: PRODUCT_ID)
        
        guard let identifier = productIdentifiers as? Set<String> else { return }
        productsRequest = SKProductsRequest(productIdentifiers: identifier)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
}

extension SubscriptionViewController: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        if response.products.count > 0 {
            iapProducts = response.products
            let purchasingProduct = response.products[0] as SKProduct
            
            // Get its price from iTunes Connect
            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = purchasingProduct.priceLocale
            let price = numberFormatter.string(from: purchasingProduct.price)
            
            var period = "Error"
            
            if let subscriptionPeriod = purchasingProduct.subscriptionPeriod {
                
                switch subscriptionPeriod.unit {
                case .day:
                    period = "day"
                case .week:
                    period = "week"
                case .month:
                    period = "month"
                case .year:
                    period = "year"
                }
            }
            
            
            if let price = price {
                priceLabel.text = "\(price)/" + period
            }
            
        }
    }
   
}

extension SubscriptionViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                
                if productID == PRODUCT_ID {
                    Settings.isSubscriptionAvailability = true
                    Settings.checkSubscriptionAvailability()
                    
                    let alert = showAlertContrller(title: "Purchase Success", message: "You've successfully purchased") {
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                    self.present(alert, animated: true)
                                        
                }
            case .failed:
                if transaction.error != nil {
                    self.present(showAlertContrller(title: "Purchase failed!", message: transaction.error!.localizedDescription), animated: true, completion: nil)
                    print(transaction.error!)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
            default: break
            }
        }
    }
    
    
}
