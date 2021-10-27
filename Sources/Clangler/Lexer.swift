import Foundation

public protocol LexerType {

}

public final class Lexer: LexerType {
    public enum Error: Swift.Error {
        case failedToScanNextCharacter
        case unterminatedString
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
                    // Todo: handle this error
                    break
                }
            default:
                if next.isNumber {

                } else if next.isIdentifierNonDigit {

                }
            }
        }

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
            case "\n":
                // Line-breaks in strings are not allowed
                throw Error.unterminatedString
            default:
                continue
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
}

extension Character {
    /// Identifiers can only start with `[a-zA-Z_]`
    var isIdentifierNonDigit: Bool {
        isLetter || self == "_"
    }
}
