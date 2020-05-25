import Parsing

public protocol SwiftXMLParserDelegate {
    func didStartDocument(_ parser: SwiftXMLParser)
    func didEndDocument(_ parser: SwiftXMLParser)
    func didStartElement(_ parser: SwiftXMLParser, elementName: String, namespaceURI: String?, attributes attributeDict: [String : String])
    func didEndElement(_ parser: SwiftXMLParser, elementName: String, namespaceURI: String?)
    func foundCharacters(_ parser: SwiftXMLParser, string: String)
    func foundIgnorableWhitespace(_ parser: SwiftXMLParser, whiteSpace: String)
    func foundComment(_ parser: SwiftXMLParser, comment: String)
    func foundCDATA(_ parser: SwiftXMLParser, CDATABlock: [UInt8])
    func errorOccurred(_ parser: SwiftXMLParser, error: Error) -> Error?
}

extension SwiftXMLParserDelegate {
    public func didStartDocument(_ parser: SwiftXMLParser) {}
    public func didEndDocument(_ parser: SwiftXMLParser) {}
    public func didStartElement(_ parser: SwiftXMLParser, elementName: String, namespaceURI: String?, attributes attributeDict: [String : String]) {}
    public func didEndElement(_ parser: SwiftXMLParser, elementName: String, namespaceURI: String?) {}
    public func foundCharacters(_ parser: SwiftXMLParser, string: String) {}
    public func foundIgnorableWhitespace(_ parser: SwiftXMLParser, whiteSpace: String) {}
    public func foundComment(_ parser: SwiftXMLParser, comment: String) {}
    public func foundCDATA(_ parser: SwiftXMLParser, CDATABlock: [UInt8]) {}
    public func errorOccurred(_ parser: SwiftXMLParser, error: Error) -> Error? { return error }
}

/// XML parser. See https://www.w3.org/TR/xml11/ for details of XML language
public class SwiftXMLParser {
    public struct Error: Swift.Error {
        private enum InternalError {
            case unexpectedCharacter
            case corruptDeclaration
            case unsupportedVersion
            case unsupportedEncoding
            case duplicateAttributes
            case unmatchingEndTag
            case missingEndTag
            case unrecognisedEscapedCharacter
        }
        private let internalError: InternalError
        
        static var unexpectedCharacter: Error { return Error(internalError: .unexpectedCharacter)}
        static var corruptDeclaration: Error { return Error(internalError: .corruptDeclaration)}
        static var unsupportedVersion: Error { return Error(internalError: .unsupportedVersion)}
        static var unsupportedEncoding: Error { return Error(internalError: .unsupportedEncoding)}
        static var duplicateAttributes: Error { return Error(internalError: .duplicateAttributes)}
        static var unmatchingEndTag: Error { return Error(internalError: .unmatchingEndTag)}
        static var missingEndTag: Error { return Error(internalError: .missingEndTag)}
        static var unrecognisedEscapedCharacter: Error { return Error(internalError: .unrecognisedEscapedCharacter)}
    }
    
    class NullDelegate: SwiftXMLParserDelegate {}
    
    public init() {
        self.delegate = NullDelegate()
    }

    public func parse(xmlString: String) throws {
        try parse(with: Parser(xmlString))
    }
    
    public func parse<Buffer: Collection>(xmlData: Buffer) throws where Buffer.Element == UInt8, Buffer.Index == Int {
        try parse(with: Parser(xmlData))
    }
    
    public func parse(with parser: Parser) throws {
        delegate.didStartDocument(self)
        
        var parser = parser
        var elementStack: [String] = []
        
        // read declaration
        var prologReader = parser
        if try prologReader.read("<"), prologReader.current() == "?" {
            try parseDeclaration(try prologReader.read(until: ">"))
            try prologReader.advance()
            parser = prologReader
        }
        
        while !parser.reachedEnd() {
            if elementStack.count == 0 {
                let whiteSpace = parser.read(while: { $0.isWhitespace || $0.isNewline })
                if whiteSpace.count > 0 {
                    delegate.foundIgnorableWhitespace(self, whiteSpace: whiteSpace.string)
                }
            }
            do {
                if try parser.read("<") {
                    let c = parser.current()
                    let contents = try parser.read(until: ">")
                    if c == "?" {
                        try parseProcessingInstructions(contents)
                    } else if c == "!" {
                        // assume comment now need to fix to parse DTD elements etc
                        try parseComment(contents)
                        // ignore DTD elements, comments,
                    } else if c == "/" {
                        let elementName = try parseEndTag(contents)
                        let poppedElementName = elementStack.popLast()
                        guard elementName == poppedElementName else { throw Error.unmatchingEndTag }
                    } else {
                        if let elementName = try parseElement(contents) {
                            elementStack.append(elementName)
                        }
                    }
                    // advance past ">"
                    parser.unsafeAdvance()
                } else if elementStack.count > 0 {
                    let contents = try parser.read(until: "<")
                    try parseCharacters(contents)
                } else {
                    throw Error.unexpectedCharacter
                }
            } catch {
                try delegateProcessError(error)
            }
        }
        
        if elementStack.count != 0 {
            try delegateProcessError(Error.missingEndTag)
        }
        
        delegate.didEndDocument(self)
    }
    
    func delegateProcessError(_ error: Swift.Error) throws {
        if let error = delegate.errorOccurred(self, error: error) {
            throw error
        }
    }
    
    func parseDeclaration(_ parser: Parser) throws {
        var parser = parser
        // advance past '?'
        parser.unsafeAdvance()
        let tag = try parseTag(&parser)
        guard tag.name.caseInsensitiveCompare("xml") == .orderedSame else { throw Error.corruptDeclaration }
        if let version = tag.attributes["version"] {
            guard (version == "1.1" || version == "1.0") else { throw Error.unsupportedVersion }
        }
        if let encoding = tag.attributes["encoding"] {
            guard encoding.caseInsensitiveCompare("utf-8") == .orderedSame else { throw Error.unsupportedEncoding }
        }
        parser.read(while: \.isWhitespace)
        guard parser.current() == "?" else { throw Error.unexpectedCharacter }
    }
    
    func parseProcessingInstructions(_ parser: Parser) throws {
    }
    
    func parseElement(_ elementParser: Parser) throws -> String? {
        var parser = elementParser
        let tag = try parseTag(&parser)
        parser.read(while: \.isWhitespace)
        
        delegate.didStartElement(self, elementName: tag.name, namespaceURI: nil, attributes: tag.attributes)
        
        if parser.current() == "/" {
            delegate.didEndElement(self, elementName: tag.name, namespaceURI: nil)
            return nil
        }
        return tag.name
    }
    
    func parseEndTag(_ endTagParser: Parser) throws -> String {
        var parser = endTagParser
        // advance past '/'
        parser.unsafeAdvance()
        guard parser.current().isNameStartChar else { throw Error.unexpectedCharacter }
        let name = parser.read(while: { $0.isNameChar })
        let nameString = name.string
        delegate.didEndElement(self, elementName: nameString, namespaceURI: nil)

        return nameString
    }
    
    func parseTag(_ parser: inout Parser) throws -> (name: String, attributes: [String: String]) {
        var attributes: [String: String] = [:]
        guard parser.current().isNameStartChar else { throw Error.unexpectedCharacter }
        let name = parser.read(while: { $0.isNameChar })
        while !parser.reachedEnd() {
            let whitespace = parser.read(while: { $0.isWhitespace })
            guard whitespace.count > 0 else { break }
            if parser.current().isNameStartChar {
                let attribute = try parseAttribute(&parser)
                guard attributes[attribute.name] == nil else { throw Error.duplicateAttributes}
                attributes[attribute.name] = attribute.value
            }
        }
        return (name: name.string, attributes: attributes)
    }

    func parseAttribute(_ parser: inout Parser) throws -> (name: String, value: String) {
        let name = parser.read(while: \.isNameChar)
        guard try parser.read("=") else { throw Error.unexpectedCharacter }
        let quotes = parser.current()
        guard quotes.isQuotes else { throw Error.unexpectedCharacter }
        parser.unsafeAdvance()
        let value = try parser.read(until: quotes)
        parser.unsafeAdvance()
        return (name: name.string, value: value.string)
    }
    
    func parseCharacters(_ characterParser: Parser) throws {
        
        var parser = characterParser
        var chunk = try parser.read(until: "&", throwOnOverflow: false)
        if parser.reachedEnd() {
            delegate.foundCharacters(self, string: characterParser.string)
            return
        }

        var output = String()
        output.reserveCapacity(characterParser.string.utf8.count)
        
        while !parser.reachedEnd() {
            output.append(contentsOf: chunk.string)
            output.append(try parseEscapedCharacter(&parser))
            chunk = try parser.read(until: "&", throwOnOverflow: false)
        }
        output.append(contentsOf: chunk.string)

        delegate.foundCharacters(self, string: output)
    }
    
    func parseEscapedCharacter(_ parser: inout Parser) throws -> Character {
        // advance past "&"
        parser.unsafeAdvance()
        let escapedCharacter = try parser.read(until: ";").string
        // advance past ";"
        parser.unsafeAdvance()
        switch escapedCharacter {
        case "amp":
            return "&"
        case "lt":
            return "<"
        case "gt":
            return ">"
        case "apos":
            return "'"
        case "quot":
            return "\""
        default:
            // character reference
            if escapedCharacter.first == "#" {
                let valueString = escapedCharacter.dropFirst()
                var value: Int? = nil
                if escapedCharacter.count > 1 && valueString.first == "x" {
                    value = Int(escapedCharacter.dropFirst(2), radix: 16)
                } else {
                    value = Int(valueString)
                }
                if let value = value, let unicodeScalar = Unicode.Scalar(value) {
                    return Character(unicodeScalar)
                }
            }
            throw Error.unrecognisedEscapedCharacter
        }
    }
    
    func parseComment(_ commentParser: Parser) throws {
        var parser = commentParser
        // skip "!--"
        try parser.advance(by: 3)
        let text = try parser.read(untilString: "--")
        delegate.foundComment(self, comment: text.string)
    }
    
    public var delegate: SwiftXMLParserDelegate
}

extension Unicode.Scalar {
    var isNameStartChar: Bool { return isLetter }
    var isNameChar: Bool { return isLetter || isNumber || self == ":" }
    var isQuotes: Bool { return self == "\"" || self == "'"}
}

