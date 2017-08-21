//
//  URL+Custom.swift
//  Source
//
//  Created by Ian McDowell on 11/18/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import Foundation

public extension URL {
    public var isDirectory: Bool {
        if let v = try? self.resourceValues(forKeys: [.isDirectoryKey]) {
            return v.isDirectory ?? false
        } else {
            return false
        }
    }

    public var fileContentModificationDate: Date? {
        var lastModified: AnyObject?

        _ = try? (self as NSURL).getResourceValue(&lastModified, forKey: URLResourceKey.contentModificationDateKey)

        return lastModified as? Date
    }
}
