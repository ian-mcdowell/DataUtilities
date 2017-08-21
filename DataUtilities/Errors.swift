//
//  Errors.swift
//  Source
//
//  Created by Ian McDowell on 4/11/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

/// An error that can occur when dealing with mock data
///
/// - isMock: The operation failed because mock data is enabled.
public enum MockDataError: LocalizedError {
    case isMock

    public var errorDescription: String? {
        return "Using mock data."
    }
}

public enum RequestError: LocalizedError {
    case parse(String, reason: String?)
    case retrieve(String, Error)
    case create(String, Error)
    case update(String, Error)
    case remove(String, Error)
    case assertionFailure(String)
    case generic(Error)

    public var errorDescription: String? {
        switch self {
        case .parse(let toParse, let reason):
            if let reason = reason {
                return "Unable to parse \(toParse), because \(reason)."
            }
            return "Unable to parse \(toParse)."
        case .retrieve(let toRetrieve, let error):
            return "Unable to retrieve \(toRetrieve). \(error.localizedDescription)"
        case .create(let toCreate, let error):
            return "Unable to create \(toCreate). \(error.localizedDescription)"
        case .update(let toUpdate, let error):
            return "Unable to update \(toUpdate). \(error.localizedDescription)"
        case .remove(let toRemove, let error):
            return "Unable to remove \(toRemove). \(error.localizedDescription)"
        case .assertionFailure(let description):
            return "Unable to perform request. \(description)"
        case .generic(let error):
            return "Unable to perform request. \(error.localizedDescription)"
        }
    }
}
