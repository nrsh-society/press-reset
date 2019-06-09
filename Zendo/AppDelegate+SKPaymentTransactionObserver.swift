import StoreKit

extension AppDelegate: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SKProduct) -> Bool {
        
        // we don't care to stop any payment tx from going through here, so
        // always let them through
        return true
    }
}
