//
//  Async.swift
//  Source
//
//  Created by Ian McDowell on 12/29/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import Foundation

public typealias AsyncMethod = (_ callback: @escaping () -> Void) -> Void
public typealias FailableAsyncMethod = (_ callback: @escaping (_ error: Error?) -> Void) -> Void
public class Async {

    /// Calls the given methods in order, then calls the `then` block when finished
    ///
    /// - Parameters:
    ///   - methods: a list of blocks to call in order
    ///   - then: the block that is called at the end.
    public class func series(_ methods: @escaping AsyncMethod..., then: @escaping () -> Void) {

        let thread = Thread.current

        // Define a method to call for each method we want to execute.

        // Has to be optional and default to nil since it is called within itself.
        var execute: ((_ method: AsyncMethod, _ remaining: [AsyncMethod]) -> Void)?

        execute = { method, remaining in

            method({
                assert(Thread.current == thread, "Thread of callback is different than thread of Async.series.\n\(Thread.current.description)\nvs.\n\(thread.description)\n")

                if let nextMethod = remaining.first {
                    var remainingMethods = remaining
                    _ = remainingMethods.removeFirst()
                    execute?(nextMethod, remainingMethods)
                } else {
                    then()
                }
            })
        }

        // Get the first method and execute it.
        var remainingMethods = methods
        if let firstMethod = methods.first {
            _ = remainingMethods.removeFirst()
            execute?(firstMethod, remainingMethods)
        } else {
            // No methods provided
            then()
        }
    }

    /// Calls the given methods in order, then calls the `then` block when finished
    ///
    /// - Parameters:
    ///   - methods: a list of blocks to call in order
    ///   - then: the block that is called at the end.
    public class func failableSeries(_ methods: @escaping FailableAsyncMethod..., then: @escaping (_ error: Error?) -> Void) {

        let thread = Thread.current

        // Define a method to call for each method we want to execute.

        // Has to be optional and default to nil since it is called within itself.
        var execute: ((_ method: FailableAsyncMethod, _ remaining: [FailableAsyncMethod]) -> Void)?

        execute = { method, remaining in

            method({ error in
                assert(Thread.current == thread, "Thread of callback is different than thread of Async.failableSeries.\n\(Thread.current.description)\nvs.\n\(thread.description)\n")

                if let error = error {
                    then(error)
                } else if let nextMethod = remaining.first {
                    var remainingMethods = remaining
                    _ = remainingMethods.removeFirst()
                    execute?(nextMethod, remainingMethods)
                } else {
                    then(nil)
                }
            })
        }

        // Get the first method and execute it.
        var remainingMethods = methods
        if let firstMethod = methods.first {
            _ = remainingMethods.removeFirst()
            execute?(firstMethod, remainingMethods)
        } else {
            // No methods provided
            then(nil)
        }
    }
}

public extension Array {

    public typealias AsyncMapMethod<T> = (_ item: Element, _ callback: @escaping (_ transformed: T) -> Void) -> Void

    /// Asynchronously maps the current array using the given transform method.
    ///
    /// - Parameters:
    ///   - transform: method that you define, which will transform the elements from the current type to the new type
    ///   - complete: method called at the end, in which the mapped elements will be passed.
    public func mapAsync<T>(_ transform: @escaping AsyncMapMethod<T>, complete: @escaping (_ mapped: [T]) -> Void) {

        let thread = Thread.current

        var mapped = [T]()

        // Define a method to call for each method we want to execute.

        // Has to be optional and default to nil since it is called within itself.
        var execute: ((_ element: Element, _ remaining: [Element]) -> Void)?

        execute = { element, remaining in

            transform(element, { transformed in

                assert(Thread.current == thread, "Thread of callback is different than thread of Async.mapAsync.\n\(Thread.current.description)\nvs.\n\(thread.description)\n")

                // Add it to our list of mapped/transformed elements
                mapped.append(transformed)

                if let next = remaining.first {
                    var remainingObjects = remaining
                    _ = remainingObjects.removeFirst()
                    execute?(next, remainingObjects)
                } else {
                    complete(mapped)
                }
            })
        }

        // Get the first method and execute it.
        var remaining = self
        if let first = remaining.first {
            _ = remaining.removeFirst()
            execute?(first, remaining)
        } else {
            // No methods provided
            complete(mapped)
        }
    }
}
