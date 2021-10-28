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
        while !cursor.isPastEnd {
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
                let lexeme = try scanStringLiteral()
                makeToken(type: .stringLiteral, lexeme: lexeme)
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
                    try scanIdentifierOrKeyword()
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

    private func scanStringLiteral() throws -> String {
        // Start with the first quote since we've already scanned it
        var lexeme = "\""
        var isNextEscaped = false

        while !cursor.isPastEnd {
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
                // Lexeme is terminated with the closing quote. return.
                return lexeme
            default:
                if next.isNewline {
                    // Line-breaks in strings are not allowed
                    throw Error.unterminatedString
                } else {
                    continue
                }
            }
        }

        // Should have returned from inside the loop upon encountering a closing quote
        throw Error.unterminatedString
    }

    private func scanCommentLine() {
        while !cursor.isPastEnd {
            if cursor.advance().isNewline {
                return
            }
        }
    }

    private func scanCommentBlock() {
        var depth = 1
        while !cursor.isPastEnd {
            let next = cursor.advance()
            switch next {
            case "*":
                if cursor.match(next: "/") {
                    depth -= 1
                    if depth == 0 { return }
                }
            case "/":
                if cursor.match(next: "*") {
                    depth += 1
                }
            default:
                continue
            }
        }
    }

    private func scanIntegerLiteral() throws {
        var integerString = String(cursor.current)
        while !cursor.isPastEnd && cursor.peek().isNumber {
            integerString.append(cursor.advance())
        }

        guard Int(integerString) != nil else {
            throw Error.failedToMakeIntegerFromLexeme(integerString)
        }

        makeToken(type: .integerLiteral, lexeme: integerString)
    }

    private func scanIdentifierOrKeyword() throws {
        var lexeme = String(cursor.current)
        while !cursor.isPastEnd {
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
