//
//  SOOrderedDictionary.swift
//  Source
//
//  Created by Ian McDowell on 8/10/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import Foundation

public struct OrderedDictionary<Tk: Hashable, Tv> {
    public var keys: Array<Tk> = []
    public var values: Dictionary<Tk, Tv> = [:]

    public var count: Int {
        assert(keys.count == values.count, "Keys and values array out of sync")
        return self.keys.count
    }

    // Explicitly define an empty initializer to prevent the default memberwise initializer from being generated
    public init() {}

    public subscript(index: Int) -> Tv? {
        get {
            if index >= self.keys.count || index < 0 {
                // Index out of bounds.
                return nil
            }

            let key = self.keys[index]
            return self.values[key]
        }
        set(newValue) {
            if index >= self.keys.count || index < 0 {
                // Index out of bounds
                return
            }

            let key = self.keys[index]
            if newValue != nil {
                self.values[key] = newValue
            } else {
                self.values.removeValue(forKey: key)
                self.keys.remove(at: index)
            }
        }
    }

    public subscript(key: Tk) -> Tv? {
        get {
            return self.values[key]
        }
        set(newValue) {
            if newValue == nil {
                self.values.removeValue(forKey: key)
                self.keys = self.keys.filter { $0 != key }
            } else {
                let oldValue = self.values.updateValue(newValue!, forKey: key)
                if oldValue == nil {
                    self.keys.append(key)
                }
            }
        }
    }

    public var description: String {
        var result = "{\n"
        for i in 0 ..< self.count {
            result += "[\(i)]: \(self.keys[i]) => \(String(describing: self[i]))\n"
        }
        result += "}"
        return result
    }
}
