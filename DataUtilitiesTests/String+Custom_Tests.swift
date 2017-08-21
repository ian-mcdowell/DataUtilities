//
//  String+Custom_Tests.swift
//  Source
//
//  Created by Ian McDowell on 12/30/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import XCTest
@testable import SourceData

class StringCustomTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPluralized() {

        let zero = String.pluralized(0, "test")
        XCTAssertEqual(zero, "0 tests")

        let one = String.pluralized(1, "test")
        XCTAssertEqual(one, "1 test")

        let two = String.pluralized(2, "test")
        XCTAssertEqual(two, "2 tests")

        let hundred = String.pluralized(100, "test")
        XCTAssertEqual(hundred, "100 tests")
    }

    func testConcatenate() {

        let c1 = String.concatenating(["a", "b", "c"])
        XCTAssertEqual(c1, "abc")

        let c2 = String.concatenating(["a", "a", "a"])
        XCTAssertEqual(c2, "aaa")

        let c3 = String.concatenating([])
        XCTAssertEqual(c3, "")

        let c4 = String.concatenating(["a", "b", "c"], separator: " ")
        XCTAssertEqual(c4, "a b c")

        let c5 = String.concatenating([], separator: " ")
        XCTAssertEqual(c5, "")

        let c6 = String.concatenating(["a"], separator: " ")
        XCTAssertEqual(c6, "a")

        let c7 = String.concatenating(["a", "a", "a"], separator: " ")
        XCTAssertEqual(c7, "a a a")
    }
}
