//
//  Array+Custom.swift
//  Source
//
//  Created by Ian McDowell on 12/27/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import Foundation

extension Array {

    public func appending(_ array: Array) -> Array {
        var t = self
        t.append(contentsOf: array)
        return t
    }
}
