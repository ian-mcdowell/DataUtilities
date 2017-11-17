//
//  ExtensionLoader.swift
//  DataUtilities
//
//  Created by Ian McDowell on 10/31/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

// A request that can be sent to the extension
public protocol ExtensionRequest : NSSecureCoding, CustomStringConvertible {
    
}

public typealias ExtensionResponseCallback = @convention(block) (NSCoding?, NSError?) -> Void

/// Class that handles communicating with an extension. This is entirely done via private methods. Oops.
/// The implementation of SourceGitResponder protocol that passes requests to the extension.
public class ExtensionLoader {
    
    // The NSExtension
    private let ext: AnyObject
    
    private typealias RequestCancellationBlock = @convention(block) (_ id: NSUUID, _ error: NSError?) -> Void
    private typealias RequestInterruptionBlock = @convention(block) (_ id: NSUUID) -> Void
    private typealias RequestCompletionBlock = @convention(block) (_ id: NSUUID, _ extensionItems: NSArray) -> Void
    
    private typealias RequestBeginCompletionBlock = @convention(block) (_ id: NSUUID) -> Void
    
    private var requests = [NSUUID: (request: ExtensionRequest, completion: ExtensionResponseCallback)]()
    
    // The NSExtension callbacks may come back in different threads. Since we are modifying the requests
    // state, we need to do all of that and our callbacks from the same thread.
    private static let extensionQueue = DispatchQueue(label: "ExtensionLoader")
    
    public init(_ extensionID: String) {
        
        // PRIVATE: Loading an NSExtension, which is not a public API
        
        let extensionClass = NSClassFromString("NS" + "Extension") as AnyObject
        let extensionSelector = NSSelectorFromString("extension" + "With" + "Identifier" + ":error:")
        
        let error: NSError? = nil
        guard let ext = extensionClass.perform(extensionSelector, with: extensionID, with: error) else {
            
            fatalError("Unable to find extension.")
        }
        
        self.ext = ext.takeUnretainedValue()
        
        let cancellationBlock: RequestCancellationBlock = { (id, error) in
            ExtensionLoader.extensionQueue.async {
                self.requestCancelled(id, error)
            }
        }
        
        let interruptionBlock: RequestInterruptionBlock = { id in
            ExtensionLoader.extensionQueue.async {
                self.requestInterrupted(id)
            }
        }
        
        let completionBlock: RequestCompletionBlock = { id, extensionItems in
            ExtensionLoader.extensionQueue.async {
                self.requestCompleted(id, extensionItems)
            }
        }
        
        _ = self.ext.perform(NSSelectorFromString("setRequestCancellationBlock:"), with: cancellationBlock)
        _ = self.ext.perform(NSSelectorFromString("setRequestInterruptionBlock:"), with: interruptionBlock)
        _ = self.ext.perform(NSSelectorFromString("setRequestCompletionBlock:"), with: completionBlock)
    }
    
    // MARK: Callbacks
    
    // The extension cancelled the request, hopefully providing us with an error as to why.
    private func requestCancelled(_ id: NSUUID, _ error: NSError?) {
        
        if let request = self.requests[id] {
            request.completion(nil, error)
            
            self.requests[id] = nil
        } else {
            print("Request \(id.uuidString) was cancelled, but no request found to notify.")
        }
    }
    
    // There was a connection issue.
    private func requestInterrupted(_ id: NSUUID) {
        
        if let request = self.requests[id] {
            request.completion(nil, NSError("Request was interrupted."))
            
            self.requests[id] = nil
        } else {
            print("Request \(id.uuidString) was interrupted, but no request was found to notify.")
        }
    }
    
    // The extension completed the request.
    // It may have passed a response or not, either one is fine.
    private func requestCompleted(_ id: NSUUID, _ extensionItems: NSArray) {
        
        var response: NSCoding? = nil
        
        // Parse out response object if possible.
        if let item = extensionItems.firstObject as? NSExtensionItem {
            
            if let responseData = item.attachments?.first as? Data {
                response = NSKeyedUnarchiver.unarchiveObject(with: responseData) as? NSCoding
            }
        }
        
        if let request = self.requests[id] {
            request.completion(response, nil)
            
            #if DEBUG
                print("Extension method successful: \(id.uuidString)")
            #endif
            self.requests[id] = nil
        } else {
            print("Request \(id.uuidString) completed, but no request was found to notify.")
        }
    }
    
    // MARK: Communicators
    
    /// Sends a request to the extension for handling. Will call the callback method on completion or if there was an issue.
    ///
    /// - Parameters:
    ///   - request: The action the extension should perform
    ///   - params: Parameters to pass along with the request.
    ///   - callback: a method to be called when the extension processes the request or has an issue.
    public func processRequest(_ request: ExtensionRequest, _ responseCallback: @escaping ExtensionResponseCallback) {
        
        let sel = NSSelectorFromString("begin" + "Extension" + "Request" + "With" + "InputItems" + ":completion:")
        
        let completion: RequestBeginCompletionBlock = { id in
            ExtensionLoader.extensionQueue.async {
                print("Extension method called: \(id.uuidString) \(request.description)")
                self.requests[id] = (request, responseCallback)
            }
        }
        
        let encodedRequest = NSKeyedArchiver.archivedData(withRootObject: request)
        
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [encodedRequest]
        
        #if DEBUG
            print("Extension method starting: \(request.description)")
        #endif
        _ = self.ext.perform(sel, with: [extensionItem], with: completion)
    }
    
}
