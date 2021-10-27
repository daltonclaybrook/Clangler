import Foundation

public protocol LexerType {

}

public final class Lexer: LexerType {
    private let fileContents: String

    public init(fileContents: String) {
        self.fileContents = fileContents
    }

    public convenience init(fileURL: URL) throws {
        self.init(fileContents: try String(contentsOf: fileURL))
    }
}
