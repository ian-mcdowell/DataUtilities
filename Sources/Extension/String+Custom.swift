//
//  String+Custom.swift
//  Source
//
//  Created by Ian McDowell on 11/19/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import Foundation

public extension String {

    public func encodeURIComponent() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-_.!~*'()")

        return self.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
    }

    /// If the string is empty, returns nil. Otherwise, will be the receiver string.
    public var ifNotEmpty: String? {
        if self.isEmpty {
            return nil
        }
        return self
    }

    public static func pluralized(_ number: Int, _ singular: String, _ plural: String? = nil) -> String {
        if number == 1 {
            return "\(number) " + singular
        } else if let plural = plural {
            return "\(number) " + plural
        } else {
            return "\(number) " + singular + "s"
        }
    }

    public static func concatenating(_ strings: [String], separator: String? = nil) -> String {
        var result = ""

        var index = 0
        for string in strings {
            result += string

            index += 1
            if index < strings.count {
                if let separator = separator {
                    result += separator
                }
            }
        }

        return result
    }
}
