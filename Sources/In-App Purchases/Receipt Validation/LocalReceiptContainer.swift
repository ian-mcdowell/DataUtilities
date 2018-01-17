//
//  LocalReceiptContainer.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/16/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation
import ssl.pkcs7
import ssl.asn1

// Private openssl method used to get integers
@_silgen_name("c2i_ASN1_INTEGER") func openssl_c2i_ASN1_INTEGER(_ a: UnsafeMutablePointer<ASN1_INTEGER>!, _ pp: UnsafeMutablePointer<UnsafePointer<UInt8>?>!, _ length: Int) -> UnsafeMutablePointer<ASN1_INTEGER>!

typealias ASN1Pointer = UnsafePointer<UInt8>?

/// Wraps a PKCS7 object,
internal class LocalReceiptContainer {
    
    private let pkcs7: UnsafeMutablePointer<PKCS7>
    init(data: Data) throws {
        let bio = BIO_new(BIO_s_mem())
        defer { BIO_free(bio) }
        BIO_write(bio, (data as NSData).bytes, Int32(data.count))
        guard let container = d2i_PKCS7_bio(bio, nil) else {
            throw PurchaseReceiptParserError.emptyContents
        }
        guard OBJ_obj2nid(container.pointee.d.sign.pointee.contents.pointee.type) == NID_pkcs7_data else {
            throw PurchaseReceiptParserError.emptyContents
        }
        self.pkcs7 = container
    }
    deinit {
        PKCS7_free(self.pkcs7)
    }
    
    var isSigned: Bool {
        return OBJ_obj2nid(pkcs7.pointee.type) == NID_pkcs7_signed
    }
    
    var attributeSet: LocalReceiptAttributeSet? {
        guard let contents = pkcs7.pointee.d.sign.pointee.contents, let octets = contents.pointee.d.data else {
            return nil
        }
        let data = Data.init(bytes: octets.pointee.data, count: Int(octets.pointee.length))
        return try? LocalReceiptAttributeSet(data: data)
    }
}

internal struct LocalReceiptAttribute {
    let type: Int
    let data: Data
    
    /// Gets an ASN1 pointer from the data object
    var ptr: ASN1Pointer {
        var bytes = [UInt8](repeating:0, count: data.count)
        data.copyBytes(to: &bytes, count: data.count)
        
        return ASN1Pointer(bytes)
    }
}

internal class LocalReceiptAttributeSet {
    
    private let ptr: ASN1Pointer
    private let end: ASN1Pointer
    
    init(data: Data) throws {
        
        let count = data.count
        
        var receiptBytes = [UInt8](repeating:0, count: count)
        data.copyBytes(to: &receiptBytes, count: count)
        
        var ptr = ASN1Pointer(receiptBytes)
        let end = ptr!.advanced(by: count)
        
        var length: Int = 0
        var tag: Int32 = 0
        var type: Int32 = 0
        ASN1_get_object(&ptr, &length, &type, &tag, end - ptr!)
        
        if (type != V_ASN1_SET) {
            throw PurchaseReceiptParserError.malformed
        }
        
        self.ptr = ptr
        self.end = end
    }
}

extension LocalReceiptAttributeSet: Sequence {
    typealias Iterator = LocalReceiptAttributeSetIterator
    
    func makeIterator() -> Iterator {
        return LocalReceiptAttributeSetIterator(ptr: self.ptr, end: self.end)
    }
    
    internal struct LocalReceiptAttributeSetIterator: IteratorProtocol {
        
        typealias Element = LocalReceiptAttribute
        
        private var ptr: ASN1Pointer
        private let end: ASN1Pointer
        
        // Iteration vars
        private var type: Int32 = 0
        private var tag: Int32 = 0
        private var length = 0
        
        init(ptr: ASN1Pointer, end: ASN1Pointer) {
            self.ptr = ptr; self.end = end
        }
        
        mutating func next() -> Element? {
            do {
                ASN1_get_object(&ptr, &length, &type, &tag, end! - ptr!)
                if (type != V_ASN1_SEQUENCE) {
                    throw PurchaseReceiptParserError.malformed
                }
                
                let sequenceEnd = ptr!.advanced(by: length)
                
                // Parse the attribute type
                let attributeType = try Int(&ptr, sequenceEnd - ptr!)
                
                // Skip attribute version
                self.consumeObject(&ptr, sequenceEnd - ptr!)
                
                // Check the attribute value
                let data = try Data(octetString: &ptr, sequenceEnd - ptr!)
                
                // Construct the attribute from what we read
                let element = LocalReceiptAttribute(type: attributeType, data: data)
                
                // Skip remaining fields
                while ptr! < sequenceEnd {
                    ASN1_get_object(&ptr, &length, &type, &tag, sequenceEnd - ptr!)
                    ptr = ptr?.advanced(by: length)
                }
                
                return element
            } catch {
                assertionFailure("Unable to retrieve element.")
                return nil
            }
        }
        
        /// Advances the pointer by the length of the object at the given pointer.
        /// For use when we don't care what kind it is or what value it is, just want to skip it.
        private func consumeObject(_ ptr: inout ASN1Pointer, _ length: Int) {
            var pClass: Int32 = 0
            var tag: Int32 = 0
            var objectLength: Int = 0
            
            ASN1_get_object(&ptr, &objectLength, &tag, &pClass, length)
            ptr = ptr!.advanced(by: objectLength)
        }
    }

}

extension Data {
    init(octetString ptr: inout ASN1Pointer, _ length: Int) throws {
        var pClass: Int32 = 0
        var tag: Int32 = 0
        var objectLength: Int = 0
        
        ASN1_get_object(&ptr, &objectLength, &tag, &pClass, length)
        if tag != V_ASN1_OCTET_STRING {
            throw PurchaseReceiptParserError.malformed
        }
        
        let data = Data(bytes: ptr!, count: objectLength)
        ptr = ptr!.advanced(by: objectLength)
        
        self = data
    }
}

extension Int {
    
    init(_ ptr: inout ASN1Pointer, _ length: Int) throws {
        // These will be set by ASN1_get_object
        var type: Int32 = 0
        var xclass: Int32 = 0
        var intLength: Int = 0
        
        ASN1_get_object(&ptr, &intLength, &type, &xclass, length)
        guard type == V_ASN1_INTEGER else {
            throw PurchaseReceiptParserError.malformed
        }
        
        let integer = openssl_c2i_ASN1_INTEGER(nil, &ptr, intLength)
        let result = ASN1_INTEGER_get(integer)
        ASN1_INTEGER_free(integer)
        
        self = result
    }
}

extension String {
    
    init(_ ptr: inout ASN1Pointer, _ length: Int) throws {
        
        // These will be set by ASN1_get_object
        var type = Int32(0)
        var xclass = Int32(0)
        var stringLength = 0
        
        ASN1_get_object(&ptr, &stringLength, &type, &xclass, length)
        
        let mutableStringPointer = UnsafeMutableRawPointer(mutating: ptr!)
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
        
        self = string
    }
}

extension Date {
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }()
    init(_ p: inout ASN1Pointer, _ length: Int) throws {
        let string = try String(&p, length)
        guard let date = Date.dateFormatter.date(from: string) else {
            throw PurchaseReceiptParserError.malformed
        }
        self = date
    }
}
