//
//  PurchaseReceiptParser.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/16/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation
import ssl.pkcs7
import ssl.objects
import ssl.sha
//import ssl.x509

enum PurchaseReceiptParserError: LocalizedError {
    case notFound
    case notLoadable(error: Error)
    case emptyContents
    case notSigned
    case malformed
    case invalidType
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Unable to find receipt"
        case .notLoadable(let error): return "Unable to load receipt: \(error.localizedDescription)"
        case .emptyContents: return "The receipt was empty."
        case .notSigned: return "The receipt was not signed."
        case .malformed: return "The receipt's data was not in a valid format."
        case .invalidType: return "A property of the receipt was an invalid type."
        }
    }
}

struct PurchaseReceiptParser {
    
    let bundle: Bundle
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    public func loadReceipt() throws -> PurchaseReceipt {
        let data = try getReceiptData()
		let container = try LocalReceiptContainer(data: data)
        try checkContainerIsSigned(container)
        // TODO: Verify it's signed by apple
        return try parse(container)
    }
    
    /// Loads the receipt as data from the appStoreReceiptURL of the bundle.
    private func getReceiptData() throws -> Data {
        guard let receiptURL = bundle.appStoreReceiptURL else { throw PurchaseReceiptParserError.notFound }
        if try !receiptURL.checkResourceIsReachable() {
            throw PurchaseReceiptParserError.notFound
        }
        do {
            return try Data.init(contentsOf: receiptURL)
        } catch {
            throw PurchaseReceiptParserError.notLoadable(error: error)
        }
    }
	
	/// Verify that the container has a signature
    private func checkContainerIsSigned(_ container: LocalReceiptContainer) throws {
        guard container.isSigned else {
            throw PurchaseReceiptParserError.notSigned
        }
    }
	
	/// Parse the container into a receipt
    private func parse(_ container: LocalReceiptContainer) throws -> PurchaseReceipt {

		guard let attributeSet = container.attributeSet else {
            throw PurchaseReceiptParserError.malformed
        }

        var bundleIdentifier: String?
        var appVersion: String?
        var opaqueValue: Data?
        var sha1Hash: Data?
        var inAppPurchaseReceipts: [InAppPurchaseReceipt] = []
        var originalAppVersion: String?
        var receiptCreationDate: Date?
        var expirationDate: Date?

        for attribute in attributeSet {
            let length = attribute.data.count
            var ap = attribute.ptr
            switch attribute.type {
            case 2:
                bundleIdentifier = try String(&ap, length)
            case 3:
                appVersion = try String(&ap, length)
            case 4:
                opaqueValue = attribute.data
            case 5:
                sha1Hash = attribute.data
            case 17:
                inAppPurchaseReceipts.append(try self.parseInAppPurchaseReceipt(LocalReceiptAttributeSet(data: attribute.data)))
            case 12:
                receiptCreationDate = try Date(&ap, length)
            case 19:
                originalAppVersion = try String(&ap, length)
            case 21:
                expirationDate = try? Date(&ap, length)
            default:
                break
            }
        }
        
        guard
            let _bundleIdentifier = bundleIdentifier,
            let _appVersion = appVersion,
            let _opaqueValue = opaqueValue,
            let _sha1Hash = sha1Hash,
            let _originalAppVersion = originalAppVersion,
            let _receiptCreationDate = receiptCreationDate
        else {
            throw PurchaseReceiptParserError.malformed
        }
        return PurchaseReceipt(bundleIdentifier: _bundleIdentifier, appVersion: _appVersion, opaqueValue: _opaqueValue, sha1: _sha1Hash, inAppPurchaseReceipt: inAppPurchaseReceipts, originalApplicationVersion: _originalAppVersion, receiptCreationDate: _receiptCreationDate, receiptExpirationDate: expirationDate)
    }
    
    private func parseInAppPurchaseReceipt(_ attributeSet: LocalReceiptAttributeSet) throws -> InAppPurchaseReceipt {

        var quantity: Int?
        var productIdentifier: String?
        var transactionIdentifier: String?
        var originalTransactionIdentifier: String?
        var purchaseDate: Date?
        var originalPurchaseDate: Date?
        var subscriptionExpirationDate: Date?
        var subscriptionIntroductoryPricePeriod: Int?
        var cancellationDate: Date?
        var webOrderLineItemId: Int?
        
        for attribute in attributeSet {
            let length = attribute.data.count
            var ap = attribute.ptr
            switch attribute.type {
            case 1701:
                quantity = try Int(&ap, length)
            case 1702:
                productIdentifier = try String(&ap, length)
            case 1703:
                transactionIdentifier = try String(&ap, length)
            case 1705:
                originalTransactionIdentifier = try String(&ap, length)
            case 1704:
                purchaseDate = try Date(&ap, length)
            case 1706:
                originalPurchaseDate = try Date(&ap, length)
            case 1708:
                subscriptionExpirationDate = try Date(&ap, length)
            case 1712:
                cancellationDate = try? Date(&ap, length)
            case 1711:
                webOrderLineItemId = try Int(&ap, length)
            case 1719:
                subscriptionIntroductoryPricePeriod = try Int(&ap, length)
            default:
                break
            }
        }
        
        guard
            let _quantity = quantity,
            let _productIdentifier = productIdentifier,
            let _transactionIdentifier = transactionIdentifier,
            let _originalTransactionIdentifier = originalTransactionIdentifier,
            let _purchaseDate = purchaseDate,
            let _originalPurchaseDate = originalPurchaseDate,
            let _subscriptionExpirationDate = subscriptionExpirationDate,
            let _subscriptionIntroductoryPricePeriod = subscriptionIntroductoryPricePeriod,
            let _webOrderLineItemId = webOrderLineItemId
        else {
            throw PurchaseReceiptParserError.malformed
        }
        return InAppPurchaseReceipt(quantity: _quantity, productIdentifier: _productIdentifier, transactionIdentifier: _transactionIdentifier, originalTransactionIdentifier: _originalTransactionIdentifier, purchaseDate: _purchaseDate, originalPurchaseDate: _originalPurchaseDate, subscriptionExpirationDate: _subscriptionExpirationDate, subscriptionIntroductoryPricePeriod: _subscriptionIntroductoryPricePeriod, cancellationDate: cancellationDate, webOrderLineItemID: _webOrderLineItemId)
    }

}
