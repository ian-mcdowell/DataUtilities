//
//  NSError+Custom.swift
//  Source
//
//  Created by Ian McDowell on 1/23/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

public extension NSError {

    public convenience init(_ localizedDescription: String) {
        self.init(domain: NSPOSIXErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
}
