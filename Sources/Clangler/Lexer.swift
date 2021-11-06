import Foundation

public typealias LexerResults = (tokens: [Token], errors: [Located<ParseError>])

public protocol LexerType {
    func scanAllTokens(fileURL: URL) throws -> LexerResults
    func scanAllTokens(fileContents: String) -> LexerResults
}

/// A utility used to scan the contents of a Clang module map file into an array of tokens
public final class Lexer: LexerType {
    private var scannedTokens: [Token] = []
    private var errors: [Located<ParseError>] = []

    private var currentLexemeLine = 0
    private var currentLexemeColumn = 0

    public init() {}

    /// Load a module map file from the provided `fileURL`, scan it, and return a list of tokens
    public func scanAllTokens(fileURL: URL) throws -> LexerResults {
        let fileContents = try String(contentsOf: fileURL)
        return scanAllTokens(fileContents: fileContents)
    }

    /// Scan the provided contents of a module map file and return a list of tokens
    public func scanAllTokens(fileContents: String) -> LexerResults {
        var cursor = Cursor(string: fileContents)
        scannedTokens = []
        errors = []

        while !cursor.isAtEnd {
            startNewLexeme(cursor: cursor)
            scanNextToken(cursor: &cursor)
        }

        // update numbers to end-of-file position
        startNewLexeme(cursor: cursor)
        makeToken(type: .endOfFile, lexeme: "")
        return (scannedTokens, errors)
    }

    // MARK: - Private helpers

    private func scanNextToken(cursor: inout Cursor) {
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
            scanStringLiteral(cursor: &cursor)
        case "/":
            if cursor.match(next: "/") {
                scanCommentLine(cursor: &cursor)
            } else if cursor.match(next: "*") {
                scanCommentBlock(cursor: &cursor)
            } else {
                // Unrecognized character. Emit error.
                emitError(.unrecognizedCharacter(next))
            }
        default:
            if next.isWhitespace {
                // Ignore whitespace
                break
            } else if next.isNumber {
                scanIntegerLiteral(cursor: &cursor)
            } else if next.isIdentifierNonDigit {
                scanIdentifierOrKeyword(cursor: &cursor)
            } else {
                // Unrecognized character. Emit error.
                emitError(.unrecognizedCharacter(next))
            }
        }
    }

    private func startNewLexeme(cursor: Cursor) {
        currentLexemeLine = cursor.currentLine
        currentLexemeColumn = cursor.currentColumn
    }

    /// Convenience function for generating an error at the current scan location
    private func emitError(_ error: ParseError) {
        errors.append(
            Located(
                value: error,
                line: currentLexemeLine,
                column: currentLexemeColumn
            )
        )
    }

    /// Convenience function for making a token using the current line and column
    private func makeToken<S>(type: TokenType, lexeme: S) where S: CustomStringConvertible {
        scannedTokens.append(
            Token(
                type: type,
                line: currentLexemeLine,
                column: currentLexemeColumn,
                lexeme: lexeme.description
            )
        )
    }

    private func scanStringLiteral(cursor: inout Cursor) {
        // Start with the first quote since we've already scanned it
        var lexeme = String(cursor.previous)
        while !cursor.isAtEnd {
            let next = cursor.advance()
            guard !next.isNewline else {
                emitError(.unterminatedString(lexeme))
                return
            }

            lexeme.append(next)
            switch next {
            case "\\" where cursor.peek().isNewline:
                lexeme.removeLast() // remove the escape character from the string
                lexeme.append(cursor.advance())
            case "\"":
                // Lexeme is terminated with the closing quote. make the token.
                makeToken(type: .stringLiteral, lexeme: lexeme)
                return
            default:
                break
            }
        }
        // Should have returned from inside the loop upon encountering a closing quote
        emitError(.unterminatedString(lexeme))
    }

    private func scanCommentLine(cursor: inout Cursor) {
        while !cursor.isAtEnd {
            if cursor.advance().isNewline {
                break
            }
        }
    }

    private func scanCommentBlock(cursor: inout Cursor) {
        while !cursor.isAtEnd {
            let next = cursor.advance()
            if next == "*" && cursor.match(next: "/") {
                break
            }
        }
    }

    private func scanIntegerLiteral(cursor: inout Cursor) {
        var integerString = String(cursor.previous)
        while !cursor.isAtEnd && cursor.peek().isNumber {
            integerString.append(cursor.advance())
        }

        // Will validate that the lexeme is parsable to an `Int` in the Parser
        makeToken(type: .integerLiteral, lexeme: integerString)
    }

    private func scanIdentifierOrKeyword(cursor: inout Cursor) {
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
