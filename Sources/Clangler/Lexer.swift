import Foundation

public protocol LexerType {

}

public final class Lexer: LexerType {
    public enum Error: Swift.Error {
        case failedToScanNextCharacter
        case unterminatedString
    }

    private let fileContents: String

    public init(fileContents: String) {
        self.fileContents = fileContents
    }

    public convenience init(fileURL: URL) throws {
        self.init(fileContents: try String(contentsOf: fileURL))
    }

    public func scanTokens() throws -> [Token] {
        let scanner = Scanner(string: fileContents)

        var currentLine = 1
        var currentColumn = 1
        var tokens: [Token] = []

        // Convenience for making the token
        func makeToken<S>(type: TokenType, lexeme: S) where S: CustomStringConvertible {
            tokens.append(
                Token(type: type, line: currentLine, column: currentColumn, lexeme: lexeme.description)
            )
        }

        while !scanner.isAtEnd {
            defer { currentColumn += 1}
            guard let next = scanner.scanCharacter() else {
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
                let lexeme = try scanStringLiteral(scanner: scanner, currentColumn: &currentColumn)
                makeToken(type: .stringLiteral, lexeme: lexeme)
            default:
                fatalError()
            }
        }

        return tokens
    }

    // MARK: - Private helpers

    private func scanStringLiteral(scanner: Scanner, currentColumn: inout Int) throws -> String {
        // Start with the first quote since we've already scanned it
        var lexeme = "\""
        var isNextEscaped = false

        while !scanner.isAtEnd {
            guard let next = scanner.scanCharacter() else {
                throw Error.failedToScanNextCharacter
            }

            lexeme.append(next)
            currentColumn += 1

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
}
