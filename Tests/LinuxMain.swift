import XCTest

import readerTests

var tests = [XCTestCaseEntry]()
tests += readerTests.allTests()
XCTMain(tests)
