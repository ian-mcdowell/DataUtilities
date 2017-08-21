//
//  SOOrderedDictionary_Tests.swift
//  Source
//
//  Created by Ian McDowell on 1/27/17.
//  Copyright © 2017 Ian McDowell. All rights reserved.
//

import XCTest
@testable import SourceData

class SOOrderedDictionaryTests: XCTestCase {

    var dictionary: OrderedDictionary<String, Int>!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        dictionary = OrderedDictionary<String, Int>()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCreation() {

        XCTAssertEqual(dictionary.count, 0)
        XCTAssertEqual(dictionary.keys.count, 0)
        XCTAssertEqual(dictionary.values.count, 0)

        XCTAssertNil(dictionary[""])

        XCTAssertNil(dictionary[0])

        XCTAssertEqual(dictionary.description, "{\n}")
    }

    func testSetKeyThenLookupKey() {

        dictionary["test"] = 10

        XCTAssertEqual(dictionary["test"], 10)
    }

    func testSetKeyAndIndexThenLookupIndex() {

        dictionary["test"] = 5
        dictionary[0] = 10

        XCTAssertEqual(dictionary[0], 10)
    }

    func testSetKeysThenLookupIndex() {

        dictionary["test1"] = 10
        dictionary["test2"] = 20
        dictionary["test3"] = 30

        XCTAssertEqual(dictionary[0], 10)
        XCTAssertEqual(dictionary[1], 20)
        XCTAssertEqual(dictionary[2], 30)

    }

    func testSetIndexesWithoutKeyThere() {

        dictionary[0] = 10

        XCTAssertEqual(dictionary.count, 0)
        XCTAssertNil(dictionary[0])
    }
}
