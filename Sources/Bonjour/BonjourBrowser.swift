//
//  BonjourBrowser.swift
//  DataUtilities
//
//  Created by Ian McDowell on 7/2/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

public class BonjourBrowser {
    
    /// The type of service to discover
    let type: String
    
    /// The domain to look in
    let domain: String
    
    /// How long to wait until timing out
    let timeout: TimeInterval
    
    private var worker: BonjourBrowserWorker? {
        didSet {
            oldValue?.stop()
        }
    }
    
    /// Create a bonjour service browser
    ///
    /// - Parameters:
    ///   - type: The type of service to discover, i.e. "_smb._tcp"
    ///   - domain: The domain to look in, i.e. "local."
    ///   - timeout: How long to search before timing out.
    public init(type: String, domain: String, timeout: TimeInterval) {
        self.type = type
        self.domain = domain
        self.timeout = timeout
    }
    
    /// Begin to search for services
    ///
    /// - Parameter callback: A method to be called when the services are found or there is an error
    public func search(_ callback: @escaping (_ services: [NetService]) -> Void) {
        
        worker = BonjourBrowserWorker(browser: self)
        
        worker?.callback = { services in
            
            // Keep a reference to the worker while its doing its thing. We set it to nil here to release our reference to it when it's done.
            self.worker?.callback = nil
            self.worker = nil
            
            callback(services)
        }
        DispatchQueue.main.async {
            self.worker?.start()
        }
    }
    
    /// Stops an ongoing search, if any. The callback will be called with an empty array.
    public func stopSearch() {
        worker?.stop()
        worker = nil
    }
    
    
    /// The worker class, which is the delegate for the NetServiceBrowser
    private class BonjourBrowserWorker: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
        
        /// A strong reference to the bonjour browser 
        let bonjourBrowser: BonjourBrowser
        
        /// The Net Service Browser that does the actual search
        let browser = NetServiceBrowser()
        
        /// The set of services that have already been found.
        private var foundServices = Set<NetService>()
        
        /// The set of services that have already been resolved.
        private var resolvedServices = Set<NetService>()
        
        /// The callback method passed into the search method.
        fileprivate var callback: ((_ services: [NetService]) -> Void)?
        
        init(browser: BonjourBrowser) {
            self.bonjourBrowser = browser
            
            super.init()
            
            self.browser.delegate = self
        }
        
        deinit {
            assert(self.callback == nil, "Callback must be nil before deinit.")
        }
        
        func start() {
            browser.searchForServices(ofType: bonjourBrowser.type, inDomain: bonjourBrowser.domain)
            browser.schedule(in: .current, forMode: .defaultRunLoopMode)
        }
        
        func stop() {
            browser.stop()
            self.callback?([])
        }
        
        // MARK: NetServiceBrowserDelegate
        
        func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
            foundServices.insert(service)
            
            service.delegate = self
            service.resolve(withTimeout: bonjourBrowser.timeout)
            service.schedule(in: .current, forMode: .defaultRunLoopMode)
        }
        
        func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
            print("Service browser did not search \(errorDict)")
            callback?([])
        }
        
        func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
            foundServices.remove(service)
        }
        
        // MARK: NetServiceDelegate
        
        func netServiceDidResolveAddress(_ sender: NetService) {
            
            resolvedServices.insert(sender)
            
            if resolvedServices.count == foundServices.count {
                callback?(Array(resolvedServices))
            }
        }
        
        func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
            print("Service did not resolve \(errorDict)")
            
            callback?([])
        }
    }
    
}

