import Foundation

public protocol LexerType {
    func scanAllTokens() throws -> [Token]
}

public final class Lexer: LexerType {
    public enum Error: Swift.Error {
        case unterminatedString
        case failedToMakeIntegerFromLexeme(String)
    }

    private let fileContents: String
    private var cursor: Cursor
    private var scannedTokens: [Token] = []

    public init(fileContents: String) {
        self.fileContents = fileContents
        self.cursor = Cursor(string: fileContents)
    }

    public convenience init(fileURL: URL) throws {
        self.init(fileContents: try String(contentsOf: fileURL))
    }

    public func scanAllTokens() throws -> [Token] {
        while !cursor.isAtEnd {
            let next = cursor.advance()
            switch next {
            case ".":
                makeToken(type: .dot, lexeme: next)
            case ",":
                makeToken(type: .comma, lexeme: next)
            case "!":
                makeToken(type: .bang, lexeme: next)
            case "*":
                makeToken(type: .star, lexeme: next)
            case "{":
                makeToken(type: .leadingBrace, lexeme: next)
            case "}":
                makeToken(type: .trailingBrace, lexeme: next)
            case "[":
                makeToken(type: .leadingBracket, lexeme: next)
            case "]":
                makeToken(type: .trailingBracket, lexeme: next)
            case "\"":
                try scanStringLiteral()
            case "/":
                if cursor.match(next: "/") {
                    scanCommentLine()
                } else if cursor.match(next: "*") {
                    scanCommentBlock()
                } else {
                    // Unrecognized character. Emit error.
                    makeError(lexeme: next)
                }
            default:
                if next.isWhitespace {
                    // Ignore whitespace
                    break
                } else if next.isNumber {
                    try scanIntegerLiteral()
                } else if next.isIdentifierNonDigit {
                    scanIdentifierOrKeyword()
                } else {
                    // Unrecognized character. Emit error.
                    makeError(lexeme: next)
                }
            }
        }

        makeToken(type: .endOfFile, lexeme: "")
        return scannedTokens
    }

    // MARK: - Private helpers

    /// Convenience function for making a token using the current line and column
    private func makeToken<S>(type: TokenType, lexeme: S) where S: CustomStringConvertible {
        scannedTokens.append(
            Token(
                type: type,
                line: cursor.currentLine,
                column: cursor.currentColumn,
                lexeme: lexeme.description
            )
        )
    }

    /// Convenience function for emitting an error token
    private func makeError<S>(lexeme: S) where S: CustomStringConvertible {
        makeToken(type: .lexerError, lexeme: lexeme)
    }

    private func scanStringLiteral() throws {
        // Start with the first quote since we've already scanned it
        var lexeme = String(cursor.previous)
        var isNextEscaped = false

        while !cursor.isAtEnd {
            let next = cursor.advance()
            lexeme.append(next)

            if isNextEscaped {
                // If this character is escaped, continue to next loop iteration
                isNextEscaped = false
                continue
            }

            switch next {
            case "\\":
                // If the scanned character is the escape character, record it
                isNextEscaped = true
            case "\"":
                // Lexeme is terminated with the closing quote. make the token.
                makeToken(type: .stringLiteral, lexeme: lexeme)
                return
            default:
                if next.isNewline {
                    // Line-breaks in strings are not allowed
                    throw Error.unterminatedString
                }
            }
        }

        // Should have returned from inside the loop upon encountering a closing quote
        throw Error.unterminatedString
    }

    private func scanCommentLine() {
        while !cursor.isAtEnd {
            if cursor.advance().isNewline {
                return
            }
        }
    }

    private func scanCommentBlock() {
        while !cursor.isAtEnd {
            let next = cursor.advance()
            if next == "*" && cursor.match(next: "/") {
                return
            }
        }
    }

    private func scanIntegerLiteral() throws {
        var integerString = String(cursor.previous)
        while !cursor.isAtEnd && cursor.peek().isNumber {
            integerString.append(cursor.advance())
        }

        guard Int(integerString) != nil else {
            throw Error.failedToMakeIntegerFromLexeme(integerString)
        }

        makeToken(type: .integerLiteral, lexeme: integerString)
    }

    private func scanIdentifierOrKeyword() {
        var lexeme = String(cursor.previous)
        while !cursor.isAtEnd {
            let next = cursor.peek()
            if next.isIdentifierNonDigit || next.isNumber {
                lexeme.append(cursor.advance())
            } else {
                break
            }
        }

        let tokenType = TokenType.tokenTypesForKeyword[lexeme] ?? .identifier
        makeToken(type: tokenType, lexeme: lexeme)
    }
}

extension Character {
    /// Identifiers can only start with `[a-zA-Z_]`
    var isIdentifierNonDigit: Bool {
        isLetter || self == "_"
    }
}
