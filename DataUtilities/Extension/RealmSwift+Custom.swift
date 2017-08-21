//
//  RealmSwift+Custom.swift
//  Source
//
//  Created by Ian McDowell on 11/18/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import RealmSwift

// Realm Results to array
extension Array where Element: Object {
    public mutating func appendContentsOf(_ newElements: Results<Element>) {
        for element in newElements {
            self.append(element)
        }
    }

    public static func fromResults(_ results: Results<Element>) -> [Element] {
        var arr = [Element]()
        arr.appendContentsOf(results)
        return arr
    }
}
