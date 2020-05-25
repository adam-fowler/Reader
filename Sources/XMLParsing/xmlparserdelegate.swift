
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

class NullDelegate: SwiftXMLParserDelegate {}
