import XCTest

import ParsingTests
import XMLParsingTests

var tests = [XCTestCaseEntry]()
tests += ParsingTests.allTests()
tests += XMLParsingTests.allTests()
XCTMain(tests)
