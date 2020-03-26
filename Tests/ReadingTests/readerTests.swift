import XCTest
@testable import Reading

final class readerTests: XCTestCase {
    func testCharacter() {
        let reader = Reader("TestString")
        XCTAssertEqual(try reader.character(), "T")
        XCTAssertEqual(try reader.character(), "e")
    }

    func testSubstring() {
        let reader = Reader("TestString")
        XCTAssertThrowsError(try reader.read(count: 23))
        XCTAssertEqual(try reader.read(count: 3), "Tes")
        XCTAssertEqual(try reader.read(count: 5), "tStri")
        XCTAssertThrowsError(try reader.read(count: 3))
        XCTAssertNoThrow(try reader.read(count: 2))
    }

    func testReadCharacter() {
        let reader = Reader("TestString")
        XCTAssertNoThrow(try reader.read("T"))
        XCTAssertNoThrow(try reader.read("e"))
        XCTAssertEqual(try reader.read("e"), false)
    }

    func testReadUntilCharacter() throws {
        let reader = Reader("TestString")
        XCTAssertEqual(try reader.read(until:"S"), "Test")
        XCTAssertEqual(try reader.read(until:"n"), "Stri")
        XCTAssertThrowsError(try reader.read(until:"!"))
    }

    func testReadUntilKeyPath() throws {
        let reader = Reader("This 154 te5t")
        XCTAssertEqual(try reader.read(until:\.isWhitespace), "This")
        XCTAssertEqual(try reader.read(until:\.isLetter), " 154 ")
        XCTAssertThrowsError(try reader.read(until:\.isNewline), "te5t")
    }

    func testReadUntilCharacterSet() throws {
        let reader = Reader("TestString")
        XCTAssertEqual(try reader.read(until:Set("Sr")), "Test")
        XCTAssertEqual(try reader.read(until:Set("abcdefg")), "Strin")
    }

    func testReadUntilString() throws {
        let reader = Reader("/*check for *comment end*/")
        XCTAssertEqual(try reader.read(until:"*/"), "/*check for *comment end")
        XCTAssertTrue(try reader.read("*/"))
    }

    func testReadWhileCharacter() throws {
        let reader = Reader("122333")
        XCTAssertEqual(reader.read(while:"1"), 1)
        XCTAssertEqual(reader.read(while:"2"), 2)
        XCTAssertEqual(reader.read(while:"3"), 3)
    }

    func testReadWhileKeyPath() throws {
        let reader = Reader("This 154 te5t")
        XCTAssertEqual(reader.read(while:\.isLetter), "This")
        XCTAssertEqual(reader.read(while:\.isWhitespace), " ")
        XCTAssertEqual(reader.read(while:\.isLetter), "")
        XCTAssertEqual(reader.read(while:\.isNumber), "154")
        XCTAssertEqual(reader.read(while:\.isWhitespace), " ")
        XCTAssertEqual(reader.read(while:\.isAlphaNumeric), "te5t")
    }

    func testReadWhileCharacterSet() throws {
        let reader = Reader("aabbcdd836de")
        XCTAssertEqual(reader.read(while:Set("abcdef")), "aabbcdd")
        XCTAssertEqual(reader.read(while:Set("123456789")), "836")
        XCTAssertEqual(reader.read(while:Set("abcdef")), "de")
    }

    func testRetreat() throws {
        let reader = Reader("abcdef")
        XCTAssertThrowsError(try reader.retreat())
        _ = try reader.read(count: 4)
        try reader.retreat(by: 3)
        XCTAssertEqual(try reader.read(count: 4), "bcde")
    }
    
    static var allTests = [
        ("testCharacter", testCharacter),
        ("testSubstring", testSubstring),
        ("testReadCharacter", testReadCharacter),
        ("testReadUntilCharacter", testReadUntilCharacter),
        ("testReadUntilKeyPath", testReadUntilKeyPath),
        ("testReadUntilCharacterSet", testReadUntilCharacterSet),
        ("testReadUntilString", testReadUntilString),
        ("testReadWhileCharacter", testReadWhileCharacter),
        ("testReadWhileKeyPath", testReadWhileKeyPath),
        ("testReadWhileCharacterSet", testReadWhileCharacterSet),
        ("testRetreat", testRetreat),
    ]
}

extension Character {
    var isAlphaNumeric: Bool {
        return isLetter || isNumber
    }
}
