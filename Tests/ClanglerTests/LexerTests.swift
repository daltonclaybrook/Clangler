import Clangler
import XCTest

final class LexerTests: XCTestCase {
    private var subject: Lexer!

    override func setUp() {
        super.setUp()
        subject = Lexer()
    }

    func testEmptyStringIsScanned() {
        let contents = ""
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        XCTAssertEqual(tokenTypes, [.endOfFile])
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testAllSymbolsAreScannedWithoutErrors() {
        let contents = ".,!*{}[]"
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        XCTAssertEqual(tokenTypes, [
            .dot, .comma, .bang, .star,
            .leadingBrace, .trailingBrace,
            .leadingBracket, .trailingBracket,
            .endOfFile
        ])
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testStringLiteralIsScanned() {
        let contents = "\"this is a string literal\""
        let results = subject.scanAllTokens(fileContents: contents)
        XCTAssertEqual(results.tokens.count, 2)
        XCTAssertEqual(results.tokens[0].type, .stringLiteral)
        XCTAssertEqual(results.tokens[0].lexeme, contents)
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testIntegerLiteralIsScanned() {
        let contents = "123"
        let results = subject.scanAllTokens(fileContents: contents)
        XCTAssertEqual(results.tokens.count, 2)
        XCTAssertEqual(results.tokens[0].type, .integerLiteral)
        XCTAssertEqual(results.tokens[0].lexeme, contents)
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testIdentifierIsScanned() {
        let contents = "MyLib"
        let results = subject.scanAllTokens(fileContents: contents)
        XCTAssertEqual(results.tokens.count, 2)
        XCTAssertEqual(results.tokens[0].type, .identifier)
        XCTAssertEqual(results.tokens[0].lexeme, contents)
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testKeywordsAreScanned() {
        let keywordsMap = TokenType.tokenTypesForKeyword
        let keywords = keywordsMap.keys.sorted()
        let contents = keywords.joined(separator: " ")
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        let expectedTokenTypes = keywords.compactMap { keywordsMap[$0] } + [.endOfFile]
        XCTAssertEqual(tokenTypes, expectedTokenTypes)
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testCommentsAreIgnored() {
        let contents = """
        module MyLib {
        // This is a comment line
        requires c99
        /*
        This is a block comment
        */
        }
        """
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        XCTAssertEqual(tokenTypes, [
            .keywordModule, .identifier, .leadingBrace,
            // comment line
            .keywordRequires, .identifier,
            // comment block
            .trailingBrace, .endOfFile
        ])
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testUnterminatedStringEmitsError() {
        let contents = "\"this is an unterminated string"
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        let errors = results.errors.map(\.value)
        XCTAssertEqual(tokenTypes, [.endOfFile])
        XCTAssertEqual(errors, [.unterminatedString(contents)])
    }

    func testUnescapedNewlineInStringLiteralEmitsError() {
        let contents = """
        "Unescaped
        "
        """
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        let errors = results.errors.map(\.value)
        XCTAssertEqual(tokenTypes, [.endOfFile])
        XCTAssertEqual(errors, [
            .unterminatedString("\"Unescaped"),
            .unterminatedString("\"")
        ])
    }

    func testEscapedNewlineInStringLiteralIsScanned() {
        let contents = """
        "Escaped\
        "
        """
        let results = subject.scanAllTokens(fileContents: contents)
        let tokenTypes = results.tokens.map(\.type)
        XCTAssertEqual(tokenTypes, [.stringLiteral, .endOfFile])
        XCTAssertTrue(results.errors.isEmpty)
    }

    func testTokenLineAndColumnNumbersAreCorrect() {
        let contents = """
        module MyLib {
            header "MyLib.h"
        }

        """
        let results = subject.scanAllTokens(fileContents: contents)
        let lines = results.tokens.map(\.line)
        let columns = results.tokens.map(\.column)
        XCTAssertEqual(lines, [1, 1, 1, 2, 2, 3, 4])
        XCTAssertEqual(columns, [1, 8, 14, 5, 12, 1, 1])
    }
}
