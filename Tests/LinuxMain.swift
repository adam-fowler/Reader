import XCTest

import ParsingTests
import XMLParsingTests

var tests = [XCTestCaseEntry]()
tests += parserTests.allTests()
tests += XMLParserTests.allTests()
XCTMain(tests)
