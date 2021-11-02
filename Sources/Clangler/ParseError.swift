public enum ParseError: Error {
    case unterminatedString(String)
    case failedToMakeIntegerFromLexeme(String)
    case unrecognizedCharacter(Character)
    case unexpectedToken(TokenType, lexeme: String, message: String)
}

extension Array: Error where Element: Error {}
