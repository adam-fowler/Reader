import Foundation

/// Reader object for parsing String buffers
public struct Parser {
    public enum Error : Swift.Error {
        case overflow
        case unexpected
        case emptyString
        case invalidCharacter
    }
    
    /// Create a Parser object
    /// - Parameter string: UTF8 data to parse
    public init<Bytes: Collection>(_ utf8Data: Bytes)  where Bytes.Element == UInt8 {
        if let buffer = utf8Data as? [UInt8] {
            self.buffer = buffer
        } else {
            self.buffer = Array(utf8Data)
        }
        self.index = 0
    }

    public init(_ string: String) {
        self.init(Array(string.utf8))
    }

    private var buffer: [UInt8]
    private var index: Int
}


public extension Parser {
    
    /// Return current character
    /// - Throws: .overflow
    /// - Returns: Current character
    mutating func character() throws -> Character {
        guard !reachedEnd() else { throw Error.overflow }
        return unsafeCurrentAndAdvance()
    }
    
    /// Read the current character and return if it is as intended. If character test returns true then move forward 1
    /// - Parameter char: character to compare against
    /// - Throws: .overflow
    /// - Returns: If current character was the one we expected
    mutating func read(_ char: Character) throws -> Bool {
        let initialIndex = index
        let c = try character()
        guard c == char else { self.index = initialIndex; return false }
        return true
    }
    
    /// Read the current character and check if keyPath is true for it If character test returns true then move forward 1
    /// - Parameter keyPath: KeyPath to check
    /// - Throws: .overflow
    /// - Returns: If keyPath returned true
    mutating func read(_ keyPath: KeyPath<Character, Bool>) throws -> Bool {
        let initialIndex = index
        let c = try character()
        guard c[keyPath: keyPath] else { self.index = initialIndex; return false }
        return true
    }
    
    /// Read the current character and check if it is in a set of characters If character test returns true then move forward 1
    /// - Parameter characterSet: Set of characters to compare against
    /// - Throws: .overflow
    /// - Returns: If current character is in character set
    mutating func read(_ characterSet: Set<Character>) throws -> Bool {
        let initialIndex = index
        let c = try character()
        guard characterSet.contains(c) else { self.index = initialIndex; return false }
        return true
    }
    
    /// Compare characters at current position against provided string. If the characters are the same as string provided advance past string
    /// - Parameter string: String to compare against
    /// - Throws: .overflow, .emptyString
    /// - Returns: If characters at current position equal string
    mutating func read(_ string: String) throws -> Bool {
        let initialIndex = index
        guard string.count > 0 else { throw Error.emptyString }
        let subString = try read(count: string.count)
        guard subString == string else { self.index = initialIndex; return false }
        return true
    }
    
    /// Read next so many characters from buffer
    /// - Parameter count: Number of characters to read
    /// - Throws: .overflow
    /// - Returns: The string read from the buffer
    mutating func read(count: Int) throws -> String {
        var count = count
        var endIndex = index
        while count > 0 {
            guard endIndex != buffer.endIndex else { throw Error.overflow }
            endIndex = skipUnicodeCharacter(at: endIndex)
            count -= 1
        }
        let string = makeString(buffer[index..<endIndex])
        index = endIndex
        return string
    }
    
    /// Read from buffer until we hit a character. Position after this is of the character we were checking for
    /// - Parameter until: Character to read until
    /// - Throws: .overflow if we hit the end of the buffer before reading character
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until: Character, throwOnOverflow: Bool = true) throws -> String {
        let startIndex = index
        while !reachedEnd() {
            if unsafeCurrent() == until {
                return makeString(buffer[startIndex..<index])
            }
            unsafeAdvance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return makeString(buffer[startIndex..<index])
    }

    /// Read from buffer until keyPath on character returns true. Position after this is of the character we were checking for
    /// - Parameter keyPath: keyPath to check
    /// - Throws: .overflow
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until keyPath: KeyPath<Character, Bool>, throwOnOverflow: Bool = true) throws -> String {
        let startIndex = index
        while !reachedEnd() {
            if unsafeCurrent()[keyPath: keyPath] {
                return makeString(buffer[startIndex..<index])
            }
            unsafeAdvance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return makeString(buffer[startIndex..<index])
    }
    
    /// Read from buffer until we hit a character in supplied set. Position after this is of the character we were checking for
    /// - Parameter characterSet: Character set to check against
    /// - Throws: .overflow
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until characterSet: Set<Character>, throwOnOverflow: Bool = true) throws -> String {
        let startIndex = index
        while !reachedEnd() {
            if characterSet.contains(unsafeCurrent()) {
                return makeString(buffer[startIndex..<index])
            }
            unsafeAdvance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return makeString(buffer[startIndex..<index])
    }
    
    /// Read from buffer until we hit a string. Position after this is of the beginning of the string we were checking for
    /// - Parameter until: String to check for
    /// - Throws: .overflow, .emptyString
    /// - Returns: String read from buffer
    @discardableResult mutating func read(untilString: String, throwOnOverflow: Bool = true) throws -> String {
        guard untilString.count > 0 else { throw Error.emptyString }
        let startIndex = index
        var foundIndex = index
        var untilIndex = untilString.startIndex
        while !reachedEnd() {
            if unsafeCurrent() == untilString[untilIndex] {
                if untilIndex == untilString.startIndex {
                    foundIndex = index
                }
                untilIndex = untilString.index(after: untilIndex)
                if untilIndex == untilString.endIndex {
                    index = foundIndex
                    let result = makeString(buffer[startIndex..<index])
                    return result
                }
            } else {
                untilIndex = untilString.startIndex
            }
            unsafeAdvance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return makeString(buffer[startIndex..<index])
    }
    
    /// Read from buffer from current position until the end of the buffer
    /// - Returns: String read from buffer
    @discardableResult mutating func readUntilTheEnd() -> String {
        let startIndex = index
        index = buffer.endIndex
        return makeString(buffer[startIndex..<index])
    }
    
    /// Read while character at current position is the one supplied
    /// - Parameter while: Character to check against
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while: Character) -> Int {
        var count = 0
        while !reachedEnd(),
            unsafeCurrent() == `while` {
            unsafeAdvance()
            count += 1
        }
        return count
    }

    /// Read while keyPath on character at current position returns true is the one supplied
    /// - Parameter while: keyPath to check
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while keyPath: KeyPath<Character, Bool>) -> String {
        let startIndex = index
        while !reachedEnd(),
            unsafeCurrent()[keyPath: keyPath] {
            unsafeAdvance()
        }
        return makeString(buffer[startIndex..<index])
    }
    
    /// Read while character at current position is in supplied set
    /// - Parameter while: character set to check
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while characterSet: Set<Character>) -> String {
        let startIndex = index
        while !reachedEnd(),
            characterSet.contains(unsafeCurrent()) {
            unsafeAdvance()
        }
        return makeString(buffer[startIndex..<index])
    }
    
    mutating func scan(format: String) throws -> [String] {
        var result: [String] = []
        var formatReader = Parser(format)
        let text = try formatReader.read(untilString: "%%", throwOnOverflow: false)
        if text.count > 0 {
            guard try read(String(text)) else { throw Error.unexpected }
        }
        
        while !formatReader.reachedEnd() {
            formatReader.unsafeAdvance()
            formatReader.unsafeAdvance()
            let text = try formatReader.read(untilString: "%%", throwOnOverflow: false)
            let resultText: String
            if text.count > 0 {
                resultText = try read(untilString: String(text))
            } else {
                resultText = readUntilTheEnd()
            }
            unsafeAdvance(by: text.count)
            result.append(resultText)
        }
        return result
    }
    
    /// Return whether we have reached the end of the buffer
    /// - Returns: Have we reached the end
    func reachedEnd() -> Bool {
        return index == buffer.endIndex
    }
}

/// Public versions of internal functions which include tests for overflow
public extension Parser {
    /// Return the character at the current position
    /// - Throws: .overflow
    /// - Returns: Character
    func current() -> Character {
        guard !reachedEnd() else { return Character(Unicode.Scalar(0)) }
        return unsafeCurrent()
    }
    
    /// Move forward one character
    /// - Throws: .overflow
    mutating func advance() throws {
        guard !reachedEnd() else { throw Error.overflow }
        return unsafeAdvance()
    }
    
    /// Move forward so many character
    /// - Parameter amount: number of characters to move forward
    /// - Throws: .overflow
    mutating func advance(by amount: Int) throws {
        var amount = amount
        while amount > 0 {
            guard !reachedEnd() else { throw Error.overflow }
            index = skipUnicodeCharacter(at: index)
            amount -= 1
        }
    }
    
    /// Move backwards one character
    /// - Throws: .overflow
    mutating func retreat() throws {
        guard index != 0 else { throw Error.overflow }
        index = backOneUnicodeCharacter(at: index)
    }
    
    /// Move back so many characters
    /// - Parameter amount: number of characters to move back
    /// - Throws: .overflow
    mutating func retreat(by amount: Int) throws {
        var amount = amount
        while amount > 0 {
            guard index != 0 else { throw Error.overflow }
            index = backOneUnicodeCharacter(at: index)
            amount -= 1
        }
    }

    mutating func unsafeAdvance() {
        index = skipUnicodeCharacter(at: index)
    }
}

// internal versions without checks
private extension Parser {
    func unsafeCurrent() -> Character {
        return Character(decodeUnicodeCharacter(at: index).0)
    }
    
    mutating func unsafeCurrentAndAdvance() -> Character {
        let (unicodeScalar, index) = decodeUnicodeCharacter(at: self.index)
        self.index = index
        return Character(unicodeScalar)
    }
    
    mutating func unsafeAdvance(by amount: Int) {
        var amount = amount
        while amount > 0 {
            index = skipUnicodeCharacter(at: index)
            amount -= 1
        }
    }
    
    mutating func _setPosition(_ index: Int) {
        self.index = index
    }

    func makeString<Bytes: Collection>(_ bytes: Bytes) -> String where Bytes.Element == UInt8, Bytes.Index == Int {
        if let string = bytes.withContiguousStorageIfAvailable({ String(decoding: $0, as: Unicode.UTF8.self)}) {
          return string
        }
        else {
          return String(decoding: bytes, as: Unicode.UTF8.self)
        }
    }}


extension Parser {
    
    func decodeUnicodeCharacter(at index: Int) -> (Unicode.Scalar, Int) {
        var index = index
        let byte1 = UInt32(buffer[index])
        var value: UInt32
        if byte1 & 0xc0 == 0xc0 {
            index += 1
            let byte2 = UInt32(buffer[index] & 0x3f)
            if byte1 & 0xe0 == 0xe0 {
                index += 1
                let byte3 = UInt32(buffer[index] & 0x3f)
                if byte1 & 0xf0 == 0xf0 {
                    index += 1
                    let byte4 = UInt32(buffer[index] & 0x3f)
                    value = (byte1 & 0x7) << 18 + byte2 << 12 + byte3 << 6 + byte4
                } else {
                    value = (byte1 & 0xf) << 12 + byte2 << 6 + byte3
                }
            } else {
                value = (byte1 & 0x1f) << 6 + byte2
            }
        } else {
            value = byte1 & 0x7f
        }
        /*guard*/ let unicodeScalar = Unicode.Scalar(value)! /*else { throw Error.invalidCharacter }*/
        return (unicodeScalar, index + 1)
    }
    
    func skipUnicodeCharacter(at index: Int) -> Int {
        if buffer[index] & 0x80 != 0x80 { return index + 1 }
        if buffer[index+1] & 0xc0 == 0x80 { return index + 2 }
        if buffer[index+2] & 0xc0 == 0x80 { return index + 3 }
        return index + 4
    }
    
    func backOneUnicodeCharacter(at index: Int) -> Int {
        if buffer[index-1] & 0xc0 != 0x80 { return index - 1 }
        if buffer[index-2] & 0xc0 != 0x80 { return index - 2 }
        if buffer[index-3] & 0xc0 != 0x80 { return index - 3 }
        return index - 4
    }
}
