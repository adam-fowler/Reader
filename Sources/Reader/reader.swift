import Foundation

public class Reader {
    public enum Error : Swift.Error {
        case overflow
        case unexpected
    }
    
    public init(_ string: String) {
        self.buffer = string
        self.position = string.startIndex
    }
    
    let buffer: String
    var position: String.Index
}

public extension Reader {
    
    func character() throws -> Character {
        guard !reachedEnd() else { throw Error.overflow }
        let c = current()
        advance()
        return c
    }
    
    func read(_ char: Character) throws {
        let c = try character()
        guard c == char else { throw Error.unexpected }
    }

    func read(_ keyPath: KeyPath<Character, Bool>) throws {
        let c = try character()
        guard c[keyPath: keyPath] else { throw Error.unexpected }
    }

    func read(_ characterSet: Set<Character>) throws {
        let c = try character()
        guard characterSet.contains(c) else { throw Error.unexpected }
    }

    func read(_ string: String) throws {
        let subString = try read(length: string.count)
        guard subString == string else { throw Error.unexpected }
    }

    func read(length: Int) throws -> Substring {
        guard buffer.distance(from: position, to: buffer.endIndex) >= length else { throw Error.overflow }
        let end = buffer.index(position, offsetBy: length)
        let subString = buffer[position..<end]
        advance(by: length)
        return subString
    }
    
    func read(until: Character) throws -> Substring {
        let startIndex = position
        while true {
            guard !reachedEnd() else { throw Error.overflow }
            if current() == until {
                let result = buffer[startIndex..<position]
                advance()
                return result
            }
            advance()
        }
    }
    
    func read(until keyPath: KeyPath<Character, Bool>) -> Substring {
        let startIndex = position
        while !reachedEnd(),
            !current()[keyPath: keyPath] {
            advance()
        }
        let result = buffer[startIndex..<position]
        advance()
        return result
    }
    
    func read(until characterSet: Set<Character>) -> Substring {
        let startIndex = position
        while !reachedEnd(),
            !characterSet.contains(current()) {
            advance()
        }
        let result = buffer[startIndex..<position]
        advance()
        return result
    }
    
    func readUntilTheEnd() -> Substring {
        let startIndex = position
        position = buffer.endIndex
        return buffer[startIndex..<position]
    }
    
    func read(while: Character) -> Int {
        var count = 0
        while !reachedEnd(),
            current() == `while` {
            advance()
            count += 1
        }
        return count
    }

    func read(while keyPath: KeyPath<Character, Bool>) -> Substring {
        let startIndex = position
        while !reachedEnd(),
            current()[keyPath: keyPath] {
            advance()
        }
        return buffer[startIndex..<position]
    }
    
    func read(while characterSet: Set<Character>) -> Substring {
        let startIndex = position
        while !reachedEnd(),
            characterSet.contains(current()) {
            advance()
        }
        return buffer[startIndex..<position]
    }
    

    func reachedEnd() -> Bool {
        return position == buffer.endIndex
    }
}

private extension Reader {
    func current() -> Character {
        return buffer[position]
    }
    
    func advance() {
        position = buffer.index(after: position)
    }
    
    func retreat() {
        position = buffer.index(before: position)
    }
    
    func advance(by amount: Int) {
        position = buffer.index(position, offsetBy: amount)
    }
}
