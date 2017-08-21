//
//  AnyObject+Custom.swift
//  Source
//
//  Created by Ian McDowell on 1/19/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

public extension NSObject {

    public static func construct<T: NSObject>(_ instance: T, _ construction: (_ object: T) -> Void) -> T {
        construction(instance)
        return instance
    }

    public static func construct<T: NSObject>(_ type: T.Type, _ construction: (_ object: T) -> Void) -> T {
        let instance = T()
        construction(instance)
        return instance
    }
}
