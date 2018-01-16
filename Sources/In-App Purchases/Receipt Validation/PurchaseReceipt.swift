//
//  PurchaseReceipt.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/15/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation

public struct InAppPurchaseReceipt {
    
    /// The number of items purchased.
    public let quantity: Int
    
    /// The product identifier of the item that was purchased.
    public let productIdentifier: String
    
    /// The transaction identifier of the item that was purchased.
    public let transactionIdentifier: String
    
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier.
    public let originalTransactionIdentifier: String
    
    /// The date and time that the item was purchased.
    public let purchaseDate: Date
    
    /// For a transaction that restores a previous transaction, the date of the original transaction.
    public let originalPurchaseDate: Date
    
    /// The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT.
    public let subscriptionExpirationDate: Date
    
    /// For an auto-renewable subscription, whether or not it is in the introductory price period.
    public let subscriptionIntroductoryPricePeriod: Int
    
    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction.
    public let cancellationDate: Date?
    
    /// The primary key for identifying subscription purchases.
    public let webOrderLineItemID: Int
}

public struct PurchaseReceipt {
    
    /// This corresponds to the value of CFBundleIdentifier in the Info.plist file. Use this value to validate if the receipt was indeed generated for your app.
    public let bundleIdentifier: String
    
    /// This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist
    public let appVersion: String
    
    /// An opaque value used, with other data, to compute the SHA-1 hash during validation
    public let opaqueValue: Data
    
    /// A SHA-1 hash, used to validate the receipt
    public let sha1: Data
    
    /// The receipt for an in-app purchase.
    /// The in-app purchase receipt for a consumable product is added to the receipt when the purchase is made.
    /// It is kept in the receipt until your app finishes that transaction. After that point, it is removed from the receipt the next time the receipt is updated -
    /// for example, when the user makes another purchase or if your app explicitly refreshes the receipt.
    /// The in-app purchase receipt for a non-consumable product, auto-renewable subscription, non-renewing subscription, or free subscription remains in the receipt indefinitely.
    public let inAppPurchaseReceipt: [InAppPurchaseReceipt]
    
    /// The version of the app that was originally purchased.
    public let originalApplicationVersion: String
    
    /// The date when the app receipt was created.
    public let receiptCreationDate: Date
    
    /// The date that the app receipt expires
    public let receiptExpirationDate: Date?

}

public extension PurchaseReceipt {
    static func retrieveVerifiedReceipt() throws -> PurchaseReceipt {
        let parser = PurchaseReceiptParser(bundle: Bundle.main)
        return try parser.loadReceipt()
    }
}
