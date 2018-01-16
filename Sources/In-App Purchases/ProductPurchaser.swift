//
//  ProductPurchaser.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/15/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation
import StoreKit

public class ProductPurchaser: NSObject, SKPaymentTransactionObserver {
    
    // Keep a set of purchasers in memory so they don't go out of scope while in use.
    private static var purchasers = [SKProduct: ProductPurchaser]()
    
    private var paymentQueue: SKPaymentQueue
    
    /// The product we are purchasing
    private var product: SKProduct
    
    /// The method the delegate will call when the purchase fails or succeeds.
    /// It is assumed if the error is nil, the product was successfully purchased.
    private var productLoadedCallback: ((_ error: Error?) -> Void)?
    
    /// Creates a product purchaser for the given product
    ///
    /// - Parameter product: the product to purchase
    public init(product: SKProduct) {
        self.product = product
        self.paymentQueue = SKPaymentQueue()
        
        super.init()
        
        ProductPurchaser.purchasers[product] = self
    }
    
    /// Purchases the SKProduct and calls the given callack when finished.
    ///
    /// - Parameters:
    ///   - quantity: How many of this product we want to buy
    ///   - callback: the completion callback. If no error has passed, the purchase was successful.
    public func purchase(quantity: Int, _ callback: @escaping (_ error: Error?) -> Void) {
        
        productLoadedCallback = { error in
            
            // Unsubscribe for notifications
            self.paymentQueue.remove(self)
            
            // Call our callback.
            callback(error)
            
            // Purchaser is finished. It's okay to deallocate it now.
            ProductPurchaser.purchasers[self.product] = nil
        }
        
        // Subscribe for notifications
        self.paymentQueue.add(self)
        
        // Create the payment and add it to the queue
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        self.paymentQueue.add(payment)
    }
    
    /// Purchases the SKProduct and calls the given callack when finished.
    ///
    /// - Parameters:
    ///   - quantity: How many of this product we want to buy
    ///   - callback: the completion callback. If no error has passed, the purchase was successful.
    public func restorePurchase(_ callback: @escaping (_ error: Error?) -> Void) {
        
        productLoadedCallback = { error in
            
            // Unsubscribe for notifications
            self.paymentQueue.remove(self)
            
            // Call our callback.
            callback(error)
            
            // Purchaser is finished. It's okay to deallocate it now.
            ProductPurchaser.purchasers[self.product] = nil
        }
        
        // Subscribe for notifications
        self.paymentQueue.add(self)
        
        // Start restore process
        self.paymentQueue.restoreCompletedTransactions()
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        // Clear out old canceled transactions
        // Also find the current purcasing transaction
        if transactions.count > 1 {
            for transaction in transactions where transaction.transactionState != .purchasing {
                queue.finishTransaction(transaction)
            }
            return
        }
        
        // There better be a callback. It was set in the purchase method.
        guard let callback = productLoadedCallback else {
            return
        }
        
        let transaction = transactions.first!
        
        switch transaction.transactionState {
        case .purchased, .restored:
            
            self.paymentQueue.finishTransaction(transaction)
            
            // The state is success.
            callback(nil)
            break
        case .failed:
            
            self.paymentQueue.finishTransaction(transaction)
            
            // Failure. :(
            callback(transaction.error)
            break
        default:
            break
        }
    }
}
