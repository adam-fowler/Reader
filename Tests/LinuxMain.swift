import XCTest

import ParsingTests
import XMLParsingTests

var tests = [XCTestCaseEntry]()
tests += ParserTests.allTests()
tests += XMLParserTests.allTests()
XCTMain(tests)
