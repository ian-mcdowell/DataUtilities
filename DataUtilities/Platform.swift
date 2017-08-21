//
//  Platform.swift
//  DataUtilities
//
//  Created by Ian McDowell on 6/10/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import Foundation

public struct Platform {

    public static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }

}
