//
//  SubscriptionViewController.swift
//  Zendo
//
//  Created by Anton Pavlov on 14/02/2019.
//  Copyright © 2019 zenbf. All rights reserved.
//

import UIKit
import StoreKit
import Mixpanel

class SubscriptionViewController: UIViewController {
    
    var PRODUCT_ID = "subscription_v1"
//        var PRODUCT_ID = "ZendoTestInApp" // test
    
    
    var productID = ""
    var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()
    var reload: (()->())?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var subButtonView: UIView! {
        didSet {
            let gr = UITapGestureRecognizer(target: self, action: #selector(subscription))
            subButtonView.addGestureRecognizer(gr)
        }
    }
    
    @IBOutlet var labels: [UILabel]!
    
    
    override func viewDidLoad()
    {
        
        super.viewDidLoad()
        
        Mixpanel.mainInstance().time(event: "phone_subscription")
        
        priceLabel.text = ""
        
        for label in labels
        {
            label.attributedText = setAttributedString(label.text ?? "")
        }
        
        fetchAvailableProducts()
        
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        Mixpanel.mainInstance().track(event: "phone_subscription")
    }
        
    func setAttributedString(_ text: String) -> NSMutableAttributedString
    {
        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.43
        
        attributedString.addAttribute(.paragraphStyle, value:paragraphStyle, range: NSMakeRange(0, attributedString.length))
        
        return attributedString
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        subButtonView.layoutIfNeeded()
        subButtonView.shadowView()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    static func loadFromStoryboard() -> SubscriptionViewController {
           let storyboard =  UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "SubscriptionViewController") as! SubscriptionViewController
           return storyboard
       }
    
    @objc func subscription() {
        if !iapProducts.isEmpty {
            purchaseProduct(product: iapProducts[0])
        }
    }
    
    @IBAction func restoreOnClick(_ sender: UIButton) {
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
    
    @IBAction func onTermsClick()
    {
         let urlT = URL(string: "https://app.termly.io/document/terms-of-use-for-website/4c956fe5-e097-47f2-9b91-5da9fcc50a1a")
        UIApplication.shared.open(urlT!)
    }
    
    @IBAction func onPrivacyClick()
    {
        let urlPP = URL(string: "http://zendo.tools/privacy")
        
        UIApplication.shared.open(urlPP!)
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
                DispatchQueue.main.async {
                    self.priceLabel.text = "\(price)/" + period
                }
                
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
                    reload?()
                    
                    let vc = SuccessSubscriptionViewController.loadFromStoryboard()
                    self.navigationController?.pushViewController(vc, animated: false)
                    
                }
            case .failed:
                
                if let error = transaction.error {
                    self.present(showAlertContrller(title: "Purchase failed!", message:  error.localizedDescription), animated: true, completion: nil)
                    print(transaction)
                }
                             
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                Settings.checkSubscriptionAvailability()
            default: break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SKProduct) -> Bool {
        
        // we don't care to stop any payment tx from going through here, so
        // always let them through
        return true
    }
    
}
