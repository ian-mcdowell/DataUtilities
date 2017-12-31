//
//  Async_Tests.swift
//  Source
//
//  Created by Ian McDowell on 12/30/16.
//  Copyright © 2016 Ian McDowell. All rights reserved.
//

import XCTest
@testable import SourceData

class AsyncTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSeries() {

        let exp = expectation(description: "series expectation")

        var arr = [Int]()
        Async.series({ callback in
            arr.append(0)
            XCTAssertEqual(arr, [0])
            callback()
        }, { callback in
            arr.append(1)
            XCTAssertEqual(arr, [0, 1])
            callback()
        }, { callback in
            arr.append(2)
            XCTAssertEqual(arr, [0, 1, 2])
            callback()
        }, { callback in
            arr.append(3)
            XCTAssertEqual(arr, [0, 1, 2, 3])
            callback()
        }, { callback in
            arr.append(4)
            XCTAssertEqual(arr, [0, 1, 2, 3, 4])
            callback()
        },
        then: {
            XCTAssertEqual(arr, [0, 1, 2, 3, 4])

            exp.fulfill()
        })

        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testFailableSeries() {

        let exp = expectation(description: "series expectation")

        var arr = [Int]()
        Async.failableSeries({ callback in
            arr.append(0)
            XCTAssertEqual(arr, [0])
            callback(nil)
        }, { callback in
            arr.append(1)
            XCTAssertEqual(arr, [0, 1])
            callback(nil)
        }, { callback in
            arr.append(2)
            XCTAssertEqual(arr, [0, 1, 2])
            callback(NSError(domain: NSPOSIXErrorDomain, code: 0, userInfo: nil))
        }, { callback in
            XCTAssertTrue(false)
            callback(nil)
        }, { callback in
            XCTAssertTrue(false)
            callback(nil)
        },
        then: { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(arr, [0, 1, 2])

            exp.fulfill()
        })

        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testMapAsync() {

        let exp = expectation(description: "mapAsync expectation")

        let arr = [0, 1, 2, 3]

        arr.mapAsync({ int, callback in
            callback(int * 2)
        },
        complete: { items in
            XCTAssertEqual(items, [0, 2, 4, 6])

            exp.fulfill()
        }
        )

        waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }
}
