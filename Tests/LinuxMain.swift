import XCTest

import ParsingTests

var tests = [XCTestCaseEntry]()
tests += parserTests.allTests()
XCTMain(tests)
