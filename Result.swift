//
//  Errorable.swift
//  Source
//
//  Created by Ian McDowell on 4/10/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

/// Similar to a Swift Optional value, except contains an error instead of none.
public enum Result<Wrapped> {

    case value(Wrapped)
    case error(Error)

    public var value: Wrapped? {
        switch self {
        case .value(let value):
            return value
        default:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .error(let error):
            return error
        default:
            return nil
        }
    }
}

extension Result: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .value(let value):
            var result = "Result(value: "
            debugPrint(value, terminator: "", to: &result)
            result += ")"
            return result
        case .error(let error):
            var result = "Result(error: "
            debugPrint(error, terminator: "", to: &result)
            result += ")"
            return result
        }
    }
}
