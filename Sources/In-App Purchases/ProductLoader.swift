//
//  ProductLoader.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/15/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation
import StoreKit

/// Class dedicated to loading a SKProduct with the given product ID.
public class ProductLoader: NSObject, SKProductsRequestDelegate {
    
    // Keep a set of loaders in memory so they don't go out of scope while in use.
    private static var loaders = [String: ProductLoader]()
    
    // The product ID that was passed in.
    private var productID: String
    
    // The request for this loader
    private var request: SKProductsRequest
    
    /// When the delegate method is called, it will call this callback, which was
    /// passed into the load(_:) method.
    private var productLoadedCallback: ((_ product: SKProduct?) -> Void)?
    
    /// Creates a product loader for the given product ID
    ///
    /// - Parameter productID: the product ID we are interested in.
    public init(productID: String) {
        self.request = SKProductsRequest(productIdentifiers: [productID])
        self.productID = productID
        
        super.init()
        
        self.request.delegate = self
        
        ProductLoader.loaders[productID] = self
    }
    
    /// Loads the SKProductsRequest and calls the given callback when finished.
    ///
    /// - Parameter callback: a callback method with the product.
    public func load(_ callback: @escaping (_ product: SKProduct?) -> Void) {
        productLoadedCallback = callback
        request.start()
    }
    
    // MARK: SKProductsRequestDelegate
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productLoadedCallback?(response.products.first)
        productLoadedCallback = nil
        
        // Loader is finished. It's okay to deallocate it now.
        ProductLoader.loaders[self.productID] = nil
    }
}
