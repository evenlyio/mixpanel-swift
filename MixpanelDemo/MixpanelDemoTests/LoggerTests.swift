//
//  LoggerTests.swift
//  MixpanelDemo
//
//  Created by Sam Green on 7/8/16.
//  Copyright © 2016 Mixpanel. All rights reserved.
//

import Foundation
import XCTest
@testable import Mixpanel

class LoggerTests: XCTestCase {
    var counter: CounterLogging!

    override func setUp() {
        super.setUp()

        counter = CounterLogging()
        Logger.addLogging(counter)
    }

    func testEnableDebug() {
        Logger.enableLevel(.Debug)

        Logger.debug(message: "logged")
        XCTAssertEqual(1, counter.count)
    }

    func testEnableInfo() {
        Logger.enableLevel(.Info)

        Logger.info(message: "logged")
        XCTAssertEqual(1, counter.count)
    }

    func testEnableWarning() {
        Logger.enableLevel(.Warning)

        Logger.warn(message: "logged")
        XCTAssertEqual(1, counter.count)
    }

    func testEnableError() {
        Logger.enableLevel(.Error)

        Logger.error(message: "logged")
        XCTAssertEqual(1, counter.count)
    }

    func testDisabledLogging() {
        Logger.disableLevel(.Debug)
        Logger.debug(message: "not logged")
        XCTAssertEqual(0, counter.count)

        Logger.disableLevel(.Error)
        Logger.error(message: "not logged")
        XCTAssertEqual(0, counter.count)

        Logger.disableLevel(.Info)
        Logger.info(message: "not logged")
        XCTAssertEqual(0, counter.count)

        Logger.disableLevel(.Warning)
        Logger.warn(message: "not logged")
        XCTAssertEqual(0, counter.count)
    }
}

/// This is a stub that implements `Logging` to be passed to our `Logger` instance for testing
class CounterLogging: Logging {
    var count = 0

    func addMessage(message message: LogMessage) {
        count = count + 1
    }
}
