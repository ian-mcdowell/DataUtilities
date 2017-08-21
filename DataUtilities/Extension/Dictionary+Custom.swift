//
//  Dictionary+Custom.swift
//  Source
//
//  Created by Ian McDowell on 4/28/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

public func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach { result[$0] = $1 }
    return result
}
