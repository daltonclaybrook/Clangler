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
