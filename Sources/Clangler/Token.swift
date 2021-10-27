/// A unit of the module map language
public struct Token {
    /// The type of the token
    let type: TokenType
    /// The line number where the token appears in the source file
    let line: Int
    /// The column number where the token appears in the source file
    let column: Int
    /// The character string which makes up the token
    let lexeme: String
}
