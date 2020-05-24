import Foundation

/// Reader object for parsing String buffers
public struct Parser<S: StringProtocol> {
    public enum Error : Swift.Error {
        case overflow
        case unexpected
        case emptyString
    }
    
    /// internal storage used to store String
    private class Storage {
        init(_ buffer: S) {
            self.buffer = buffer
        }
        let buffer: S
    }

    private let _storage: Storage
    
    /// Create a Reader object
    /// - Parameter string: String to parse
    public init(_ string: S) {
        self._storage = Storage(string)
        self.position = string.startIndex
    }
    
    private var buffer: S { return _storage.buffer }
    private var position: S.Index
}

public extension Parser {
    
    /// Return current character
    /// - Throws: .overflow
    /// - Returns: Current character
    mutating func character() throws -> Character {
        guard !reachedEnd() else { throw Error.overflow }
        let c = _current()
        _advance()
        return c
    }
    
    /// Read the current character and return if it is as intended. If character test returns true then move forward 1
    /// - Parameter char: character to compare against
    /// - Throws: .overflow
    /// - Returns: If current character was the one we expected
    mutating func read(_ char: Character) throws -> Bool {
        let c = try character()
        guard c == char else { _retreat(); return false }
        return true
    }
    
    /// Read the current character and check if keyPath is true for it If character test returns true then move forward 1
    /// - Parameter keyPath: KeyPath to check
    /// - Throws: .overflow
    /// - Returns: If keyPath returned true
    mutating func read(_ keyPath: KeyPath<Character, Bool>) throws -> Bool {
        let c = try character()
        guard c[keyPath: keyPath] else { _retreat(); return false }
        return true
    }
    
    /// Read the current character and check if it is in a set of characters If character test returns true then move forward 1
    /// - Parameter characterSet: Set of characters to compare against
    /// - Throws: .overflow
    /// - Returns: If current character is in character set
    mutating func read(_ characterSet: Set<Character>) throws -> Bool {
        let c = try character()
        guard characterSet.contains(c) else { _retreat(); return false }
        return true
    }
    
    /// Compare characters at current position against provided string. If the characters are the same as string provided advance past string
    /// - Parameter string: String to compare against
    /// - Throws: .overflow, .emptyString
    /// - Returns: If characters at current position equal string
    mutating func read(_ string: String) throws -> Bool {
        guard string.count > 0 else { throw Error.emptyString }
        let subString = try read(count: string.count)
        guard subString == string else { _retreat(by: string.count); return false }
        return true
    }
    
    /// Read next so many characters from buffer
    /// - Parameter count: Number of characters to read
    /// - Throws: .overflow
    /// - Returns: The string read from the buffer
    mutating func read(count: Int) throws -> S.SubSequence {
        guard buffer.distance(from: position, to: buffer.endIndex) >= count else { throw Error.overflow }
        let end = buffer.index(position, offsetBy: count)
        let subString = buffer[position..<end]
        _advance(by: count)
        return subString
    }
    
    /// Read from buffer until we hit a character. Position after this is of the character we were checking for
    /// - Parameter until: Character to read until
    /// - Throws: .overflow if we hit the end of the buffer before reading character
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until: Character, throwOnOverflow: Bool = true) throws -> S.SubSequence {
        let startIndex = position
        while !reachedEnd() {
            if _current() == until {
                return buffer[startIndex..<position]
            }
            _advance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return buffer[startIndex..<position]
    }
    
    /// Read from buffer until we hit a string. Position after this is of the beginning of the string we were checking for
    /// - Parameter until: String to check for
    /// - Throws: .overflow, .emptyString
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until: String, throwOnOverflow: Bool = true) throws -> S.SubSequence {
        guard until.count > 0 else { throw Error.emptyString }
        let startIndex = position
        var untilIndex = until.startIndex
        while !reachedEnd() {
            if _current() == until[untilIndex] {
                untilIndex = until.index(after: untilIndex)
                if untilIndex == until.endIndex {
                    if until.count > 1 {
                        _retreat(by: until.count-1)
                    }
                    let result = buffer[startIndex..<position]
                    return result
                }
            } else {
                untilIndex = until.startIndex
            }
            _advance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return buffer[startIndex..<position]
    }
    
    /// Read from buffer until keyPath on character returns true. Position after this is of the character we were checking for
    /// - Parameter keyPath: keyPath to check
    /// - Throws: .overflow
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until keyPath: KeyPath<Character, Bool>, throwOnOverflow: Bool = true) throws -> S.SubSequence {
        let startIndex = position
        while !reachedEnd() {
            if _current()[keyPath: keyPath] {
                return buffer[startIndex..<position]
            }
            _advance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return buffer[startIndex..<position]
    }
    
    /// Read from buffer until we hit a character in supplied set. Position after this is of the character we were checking for
    /// - Parameter characterSet: Character set to check against
    /// - Throws: .overflow
    /// - Returns: String read from buffer
    @discardableResult mutating func read(until characterSet: Set<Character>, throwOnOverflow: Bool = true) throws -> S.SubSequence {
        let startIndex = position
        while !reachedEnd() {
            if characterSet.contains(_current()) {
                return buffer[startIndex..<position]
            }
            _advance()
        }
        if throwOnOverflow {
            _setPosition(startIndex)
            throw Error.overflow
        }
        return buffer[startIndex..<position]
    }
    
    /// Read from buffer from current position until the end of the buffer
    /// - Returns: String read from buffer
    @discardableResult mutating func readUntilTheEnd() -> S.SubSequence {
        let startIndex = position
        position = buffer.endIndex
        return buffer[startIndex..<position]
    }
    
    /// Read while character at current position is the one supplied
    /// - Parameter while: Character to check against
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while: Character) -> Int {
        var count = 0
        while !reachedEnd(),
            _current() == `while` {
            _advance()
            count += 1
        }
        return count
    }

    /// Read while keyPath on character at current position returns true is the one supplied
    /// - Parameter while: keyPath to check
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while keyPath: KeyPath<Character, Bool>) -> S.SubSequence {
        let startIndex = position
        while !reachedEnd(),
            _current()[keyPath: keyPath] {
            _advance()
        }
        return buffer[startIndex..<position]
    }
    
    /// Read while character at current position is in supplied set
    /// - Parameter while: character set to check
    /// - Returns: String read from buffer
    @discardableResult mutating func read(while characterSet: Set<Character>) -> S.SubSequence {
        let startIndex = position
        while !reachedEnd(),
            characterSet.contains(_current()) {
            _advance()
        }
        return buffer[startIndex..<position]
    }
    
    mutating func scan(format: String) throws -> [S.SubSequence] {
        var result: [S.SubSequence] = []
        var formatReader = Parser<String>(format)
        let text = try formatReader.read(until: "%%", throwOnOverflow: false)
        if text.count > 0 {
            guard try read(String(text)) else { throw Error.unexpected }
        }
        
        while !formatReader.reachedEnd() {
            formatReader._advance(by: 2)
            let text = try formatReader.read(until: "%%", throwOnOverflow: false)
            let resultText: S.SubSequence
            if text.count > 0 {
                resultText = try read(until: String(text))
            } else {
                resultText = readUntilTheEnd()
            }
            _advance(by: text.count)
            result.append(resultText)
        }
        return result
    }
    
    /// Return whether we have reached the end of the buffer
    /// - Returns: Have we reached the end
    func reachedEnd() -> Bool {
        return position == buffer.endIndex
    }
}

/// Public versions of internal functions which include tests for overflow
public extension Parser {
    /// Return the character at the current position
    /// - Throws: .overflow
    /// - Returns: Character
    func current() throws -> Character {
        guard !reachedEnd() else { throw Error.overflow }
        return _current()
    }
    
    /// Move forward one character
    /// - Throws: .overflow
    mutating func advance() throws {
        guard !reachedEnd() else { throw Error.overflow }
        return _advance()
    }
    
    /// Move back one character
    /// - Throws: .overflow
    mutating func retreat() throws {
        guard position != buffer.startIndex else { throw Error.overflow }
        return _retreat()
    }
    
    /// Move forward so many character
    /// - Parameter amount: number of characters to move forward
    /// - Throws: .overflow
    mutating func advance(by amount: Int) throws {
        guard buffer.distance(from: position, to: buffer.endIndex) >= amount else { throw Error.overflow }
        return _advance(by: amount)
    }
    
    /// Move back so many characters
    /// - Parameter amount: number of characters to move back
    /// - Throws: .overflow
    mutating func retreat(by amount: Int) throws {
        guard buffer.distance(from: buffer.startIndex, to: position) >= amount else { throw Error.overflow }
        return _retreat(by: amount)
    }
}

// internal versions without checks
private extension Parser {
    func _current() -> Character {
        return buffer[position]
    }
    
    mutating func _advance() {
        position = buffer.index(after: position)
    }
    
    mutating func _retreat() {
        position = buffer.index(before: position)
    }
    
    mutating func _advance(by amount: Int) {
        position = buffer.index(position, offsetBy: amount)
    }
    
    mutating func _retreat(by amount: Int) {
        position = buffer.index(position, offsetBy: -amount)
    }
    
    mutating func _setPosition(_ position: String.Index) {
        self.position = position
    }
}
