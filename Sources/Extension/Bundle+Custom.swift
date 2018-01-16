//
//  Bundle+Custom.swift
//  DataUtilities
//
//  Created by Ian McDowell on 1/10/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation

public extension Bundle {
    
    static var mainAppBundle: Bundle {
        var bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                bundle = otherBundle
            }
        }
        return bundle
    }
}
