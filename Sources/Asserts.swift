//
//  Asserts.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/10/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation

/// Assert that we are currently on the main thread
public func assertOnMainQueue() {
    dispatchPrecondition(condition: .onQueue(.main))
}

/// Assert that we are currently on the given thread
public func assertOnQueue(_ queue: DispatchQueue) {
    dispatchPrecondition(condition: .onQueue(queue))
}

public func assertNotOnQueue(_ queue: DispatchQueue) {
    dispatchPrecondition(condition: .notOnQueue(queue))
}
