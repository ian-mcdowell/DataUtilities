//
//  PurchaseReceiptParser.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/16/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation
import openssl.pkcs7
import openssl.objects
import openssl.sha
//import openssl.x509

@_silgen_name("c2i_ASN1_INTEGER") func openssl_c2i_ASN1_INTEGER(_ a: UnsafeMutablePointer<ASN1_INTEGER>!, _ pp: UnsafeMutablePointer<UnsafePointer<UInt8>?>!, _ length: Int) -> UnsafeMutablePointer<ASN1_INTEGER>!

enum PurchaseReceiptParserError: LocalizedError {
    case notLoadable(error: Error)
    case emptyContents
    case notSigned
    case appleRootNotFound
    case invalidSignature
    case malformed
    case invalidType
    
    var errorDescription: String? {
        switch self {
        case .notLoadable(let error): return "Unable to load receipt: \(error.localizedDescription)"
        case .emptyContents: return "The receipt was empty."
        case .notSigned: return "The receipt was not signed."
        case .appleRootNotFound: return "Apple's root certificate not found."
        case .invalidSignature: return "Receipt was not signed by Apple."
        case .malformed: return "The receipt's data was not in a valid format."
        case .invalidType: return "A property of the receipt was an invalid type."
        }
    }
}

class PurchaseReceiptParser {
    private typealias Container = UnsafeMutablePointer<PKCS7>
    private typealias ParsePointer = UnsafePointer<UInt8>?
    
    let bundle: Bundle
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    public func loadReceipt() throws -> PurchaseReceipt? {
        guard let data = try getReceiptData() else {
            return nil
        }
        let container = try getContainer(fromData: data)
        try checkContainerIsSigned(container)
        return try parse(container)
    }
    
    /// Loads the receipt as data from the appStoreReceiptURL of the bundle.
    private func getReceiptData() throws -> Data? {
        guard let receiptURL = bundle.appStoreReceiptURL, (try? receiptURL.checkResourceIsReachable()) ?? false else { return nil }
        do {
            return try Data.init(contentsOf: receiptURL)
        } catch {
            throw PurchaseReceiptParserError.notLoadable(error: error)
        }
    }
    
    /// Retrieves a PKCS7 container from the given data.
    private func getContainer(fromData data: Data) throws -> Container {
        let bio = BIO_new(BIO_s_mem())
        BIO_write(bio, (data as NSData).bytes, Int32(data.count))
        guard let container = d2i_PKCS7_bio(bio, nil) else {
            throw PurchaseReceiptParserError.emptyContents
        }
        guard OBJ_obj2nid(container.pointee.d.sign.pointee.contents.pointee.type) == NID_pkcs7_data else {
            throw PurchaseReceiptParserError.emptyContents
        }
        return container
    }
    
    private func checkContainerIsSigned(_ container: Container) throws {
        guard OBJ_obj2nid(container.pointee.type) == NID_pkcs7_signed else {
            throw PurchaseReceiptParserError.notSigned
        }
        
        guard
            let appleRootCertificateURL = Bundle.init(for: PurchaseReceiptParser.self).url(forResource: "AppleIncRootCertificate", withExtension: "cer"),
            let appleRootCertificateData = try? Data(contentsOf: appleRootCertificateURL)
        else {
            throw PurchaseReceiptParserError.appleRootNotFound
        }
        
        let appleRootCertificateBIO = BIO_new(BIO_s_mem())
        BIO_write(appleRootCertificateBIO, (appleRootCertificateData as NSData).bytes, Int32(appleRootCertificateData.count))
        let appleRootCertificateX509 = d2i_X509_bio(appleRootCertificateBIO, nil)

        let x509CertificateStore = X509_STORE_new()
        X509_STORE_add_cert(x509CertificateStore, appleRootCertificateX509)
        
        if PKCS7_verify(container, nil, x509CertificateStore, nil, nil, 0) != 1 {
            throw PurchaseReceiptParserError.invalidSignature
        }
    }
    
    private func parse(_ container: Container) throws -> PurchaseReceipt {
        
        guard let contents = container.pointee.d.sign.pointee.contents, let octets = contents.pointee.d.data else {
            throw PurchaseReceiptParserError.malformed
        }
        
        var p: ParsePointer = UnsafePointer(octets.pointee.data)
        let endOfPayload = p!.advanced(by: Int(octets.pointee.length))
        
        var type = Int32(0)
        var xclass = Int32(0)
        var length = 0
        
        ASN1_get_object(&p, &length, &type, &xclass, Int(octets.pointee.length))
        
        // Payload must be an ASN1 Set
        guard type == V_ASN1_SET else {
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
        
        // Decode Payload
        // Step through payload (ASN1 Set) and parse each ASN1 Sequence within (ASN1 Sets contain one or more ASN1 Sequences)
        while p! < endOfPayload {
            
            // Get next ASN1 Sequence
            ASN1_get_object(&p, &length, &type, &xclass, p!.distance(to: endOfPayload))
            
            // ASN1 Object type must be an ASN1 Sequence
            guard type == V_ASN1_SEQUENCE else {
                throw PurchaseReceiptParserError.malformed
            }
            
            // Attribute type of ASN1 Sequence must be an Integer

            let attributeType = try decodeASN1Int(&p, p!.distance(to: endOfPayload), &length)

            
            // Attribute version of ASN1 Sequence must be an Integer, but we don't care about its value

            let _ = try decodeASN1Int(&p, p!.distance(to: endOfPayload), &length)
            
            // Get ASN1 Sequence value
            ASN1_get_object(&p, &length, &type, &xclass, p!.distance(to: endOfPayload))
            
            // ASN1 Sequence value must be an ASN1 Octet String
            guard type == V_ASN1_OCTET_STRING else {
                throw PurchaseReceiptParserError.malformed
            }
            
            // Decode attributes
            var ap = p
            switch attributeType {
            case 2:
                bundleIdentifier = try decodeASN1String(&ap, length)
            case 3:
                appVersion = try decodeASN1String(&ap, length)
            case 4:
                opaqueValue = NSData(bytes: ap, length: length) as Data
            case 5:
                sha1Hash = NSData(bytes: ap, length: length) as Data
            case 17:
                let iapReceipt = try parseInAppPurchaseReceipt(&ap, length)
                inAppPurchaseReceipts.append(iapReceipt)
            case 12:
                receiptCreationDate = try decodeASN1Date(&ap, length)
            case 19:
                originalAppVersion = try decodeASN1String(&ap, length)
            case 21:
                expirationDate = try decodeASN1Date(&ap, length)
            default:
                break
            }
            
            p = p?.advanced(by: length)
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
        return PurchaseReceipt(bundleIdentifier: _bundleIdentifier, appVersion: _appVersion, opaqueValue: _opaqueValue, sha1: _sha1Hash, inAppPurchaseReceipts: inAppPurchaseReceipts, originalApplicationVersion: _originalAppVersion, receiptCreationDate: _receiptCreationDate, receiptExpirationDate: expirationDate)
    }
    
    private func parseInAppPurchaseReceipt(_ p: inout ParsePointer, _ plength: Int) throws -> InAppPurchaseReceipt {

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
        
        let endOfPayload = p!.advanced(by: plength)
        var type = Int32(0)
        var xclass = Int32(0)
        var length = 0
        
        ASN1_get_object(&p, &length, &type, &xclass, plength)
        
        // Payload must be an ASN1 Set
        guard type == V_ASN1_SET else {
            throw PurchaseReceiptParserError.malformed
        }
        
        // Decode Payload
        // Step through payload (ASN1 Set) and parse each ASN1 Sequence within (ASN1 Sets contain one or more ASN1 Sequences)
        while p! < endOfPayload {
            
            // Get next ASN1 Sequence
            ASN1_get_object(&p, &length, &type, &xclass, p!.distance(to: endOfPayload))
            
            // ASN1 Object type must be an ASN1 Sequence
            guard type == V_ASN1_SEQUENCE else {
                throw PurchaseReceiptParserError.malformed
            }
            
            // Attribute type of ASN1 Sequence must be an Integer
            let attributeType = try decodeASN1Int(&p, p!.distance(to: endOfPayload), &length)
            
            // Attribute version of ASN1 Sequence must be an Integer, but we don't care about its value
            let _ = try decodeASN1Int(&p, p!.distance(to: endOfPayload), &length)
            
            // Get ASN1 Sequence value
            ASN1_get_object(&p, &length, &type, &xclass, p!.distance(to: endOfPayload))
            
            // ASN1 Sequence value must be an ASN1 Octet String
            guard type == V_ASN1_OCTET_STRING else {
                throw PurchaseReceiptParserError.malformed
            }
            
            var ap = p
            // Decode attributes
            switch attributeType {
            case 1701:
                quantity = try decodeASN1Int(&ap, length)
            case 1702:
                productIdentifier = try decodeASN1String(&ap, length)
            case 1703:
                transactionIdentifier = try decodeASN1String(&ap, length)
            case 1705:
                originalTransactionIdentifier = try decodeASN1String(&ap, length)
            case 1704:
                purchaseDate = try decodeASN1Date(&ap, length)
            case 1706:
                originalPurchaseDate = try decodeASN1Date(&ap, length)
            case 1708:
                subscriptionExpirationDate = try decodeASN1Date(&ap, length)
            case 1712:
                cancellationDate = try decodeASN1Date(&ap, length)
            case 1711:
                webOrderLineItemId = try decodeASN1Int(&ap, length)
            case 1719:
                subscriptionIntroductoryPricePeriod = try decodeASN1Int(&ap, length)
            default:
                break
            }
            
            p = p?.advanced(by: length)
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
    
    private func decodeASN1Int(_ p: inout ParsePointer, _ length: Int) throws -> Int {
        var discard: Int = 0
        return try decodeASN1Int(&p, length, &discard)
    }
    
    private func decodeASN1Int(_ p: inout ParsePointer, _ length: Int, _ intLength: inout Int) throws -> Int {
        // These will be set by ASN1_get_object
        var type = Int32(0)
        var xclass = Int32(0)
        
        ASN1_get_object(&p, &intLength, &type, &xclass, length)
        guard type == V_ASN1_INTEGER else {
            throw PurchaseReceiptParserError.malformed
        }
        
        let integer = openssl_c2i_ASN1_INTEGER(nil, &p, intLength)
        let result = ASN1_INTEGER_get(integer)
        ASN1_INTEGER_free(integer)
        
        return result
    }
    
    private func decodeASN1String(_ p: inout ParsePointer, _ length: Int) throws -> String {

        // These will be set by ASN1_get_object
        var type = Int32(0)
        var xclass = Int32(0)
        var stringLength = 0
        
        ASN1_get_object(&p, &stringLength, &type, &xclass, length)
        
        let mutableStringPointer = UnsafeMutableRawPointer(mutating: p!)
        let encoding: String.Encoding
        switch type {
        case V_ASN1_UTF8STRING:
            encoding = .utf8
        case V_ASN1_IA5STRING:
            encoding = .ascii
        default:
            throw PurchaseReceiptParserError.malformed
        }
        
        guard let string = String(bytesNoCopy: mutableStringPointer, length: stringLength, encoding: encoding, freeWhenDone: false) else {
            throw PurchaseReceiptParserError.malformed
        }
        
        return string
    }
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
    private func decodeASN1Date(_ p: inout ParsePointer, _ length: Int) throws -> Date? {
        let string = try self.decodeASN1String(&p, length)
        if string.isEmpty { return nil }
        guard let date = PurchaseReceiptParser.dateFormatter.date(from: string) else {
            throw PurchaseReceiptParserError.malformed
        }
        return date
    }

}
