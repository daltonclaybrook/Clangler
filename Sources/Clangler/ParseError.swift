/// Errors that can be reported by the Lexer/Parser
public enum ParseError: Error, Equatable {
    /// A string literal could not be terminated by a closing quote. This can be caused by an
    /// unescaped newline, end of file, etc.
    case unterminatedString(String)
    /// Encountered a number while scanning, but could not initialize an `Int` from it
    case failedToMakeIntegerFromLexeme(String)
    /// Encountered a character that is not part of the Clang module map grammar
    case unrecognizedCharacter(Character)
    /// Encountered an unexpected token while parsing
    case unexpectedToken(TokenType, lexeme: String, message: String)
}

extension ParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unterminatedString(let string):
            return "Unterminated string: \(string)"
        case .failedToMakeIntegerFromLexeme(let lexeme):
            return "Could not initialize an integer from the lexeme: \(lexeme)"
        case .unrecognizedCharacter(let character):
            return "Unrecognized character: \(character)"
        case .unexpectedToken(_, _, let message):
            return message
        }
    }
}

extension Array: Error where Element: Error {}
