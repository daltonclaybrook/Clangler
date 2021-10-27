import Foundation

public protocol LexerType {

}

public final class Lexer: LexerType {
    public enum Error: Swift.Error {
        case failedToScanNextCharacter
        case unterminatedString
        case failedToMakeIntegerFromLexeme(String)
    }

    private let fileContents: String
    private let scanner: Scanner

    private var currentLine = 1
    private var currentColumn = 1
    private var scannedTokens: [Token] = []

    public init(fileContents: String) {
        self.fileContents = fileContents
        self.scanner = Scanner(string: fileContents)
    }

    public convenience init(fileURL: URL) throws {
        self.init(fileContents: try String(contentsOf: fileURL))
    }

    public func scanAllTokens() throws -> [Token] {
        while !scanner.isAtEnd {
            guard let next = advanceScanner() else {
                throw Error.failedToScanNextCharacter
            }

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
                let lexeme = try scanStringLiteral(scanner: scanner)
                makeToken(type: .stringLiteral, lexeme: lexeme)
            case "/":
                if match(next: "/") {
                    scanCommentLine()
                } else if match(next: "*") {
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
                    try scanIntegerLiteral(startWith: next)
                } else if next.isIdentifierNonDigit {
                    try scanIdentifierOrKeyword(startWith: next)
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
                line: currentLine,
                column: currentColumn,
                lexeme: lexeme.description
            )
        )
    }

    /// Convenience function for emitting an error token
    private func makeError<S>(lexeme: S) where S: CustomStringConvertible {
        makeToken(type: .lexerError, lexeme: lexeme)
    }

    /// If the next scanned character matches the provided character, advance the scanner and return
    /// `true`. Otherwise, do not advance the scanner and return `false`.
    private func match(next: Character) -> Bool {
        guard !scanner.isAtEnd, let scanned = scanner.scanCharacter()
        else { return false }

        if next == scanned {
            updateLineAndColumn(for: scanned)
            return true
        } else {
            // rewind scanner
            scanner.currentIndex = scanner.string.index(before: scanner.currentIndex)
            return false
        }
    }

    private func advanceScanner() -> Character? {
        guard let next = scanner.scanCharacter() else { return nil }
        updateLineAndColumn(for: next)
        return next
    }

    private func updateLineAndColumn(for next: Character) {
        if next.isNewline {
            currentLine += 1
            currentColumn = 1
        } else {
            currentColumn += 1
        }
    }

    private func scanStringLiteral(scanner: Scanner) throws -> String {
        // Start with the first quote since we've already scanned it
        var lexeme = "\""
        var isNextEscaped = false

        while !scanner.isAtEnd {
            guard let next = advanceScanner() else {
                throw Error.failedToScanNextCharacter
            }

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
        while !scanner.isAtEnd {
            guard let next = advanceScanner() else { return }
            if next.isNewline {
                return
            }
        }
    }

    private func scanCommentBlock() {
        var depth = 1
        while !scanner.isAtEnd {
            guard let next = advanceScanner() else { return }
            switch next {
            case "*":
                if match(next: "/") {
                    depth -= 1
                    if depth == 0 { return }
                }
            case "/":
                if match(next: "*") {
                    depth += 1
                }
            default:
                continue
            }
        }
    }

    private func scanIntegerLiteral(startWith: Character) throws {
        var integerString = String(startWith)
        while !scanner.isAtEnd {
            guard let next = advanceScanner() else {
                throw Error.failedToScanNextCharacter
            }

            if next.isNumber {
                integerString.append(next)
            } else {
                // break out of the loop and make the token
                break
            }
        }

        guard Int(integerString) != nil else {
            throw Error.failedToMakeIntegerFromLexeme(integerString)
        }

        makeToken(type: .integerLiteral, lexeme: integerString)
    }

    private func scanIdentifierOrKeyword(startWith: Character) throws {
        var lexeme = String(startWith)
        while !scanner.isAtEnd {
            guard let next = advanceScanner() else {
                throw Error.failedToScanNextCharacter
            }

            if next.isIdentifierNonDigit || next.isNumber {
                lexeme.append(next)
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
