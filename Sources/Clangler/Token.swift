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

    public init(
        type: TokenType,
        line: Int,
        column: Int,
        lexeme: String
    ) {
        self.type = type
        self.line = line
        self.column = column
        self.lexeme = lexeme
    }
}
