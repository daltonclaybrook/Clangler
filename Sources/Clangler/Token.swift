/// A unit of the module map language
public struct Token {
    /// The type of the token
    public let type: TokenType
    /// The line number where the token appears in the source file
    public let line: Int
    /// The column number where the token appears in the source file
    public let column: Int
    /// The character string which makes up the token
    public let lexeme: String
}

public extension Token {
    var stringLiteralValue: String {
        precondition(type == .stringLiteral, "The token is not a string literal")

        /// Strip leading and trailing quotes
        var value = lexeme
        value.removeFirst()
        value.removeLast()
        return value
    }
}
