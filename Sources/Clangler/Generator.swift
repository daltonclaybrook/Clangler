import Foundation

/// Utility used to generate module map file contents from an abstract syntax tree (AST)
/// representation. This is the reverse of `Parser`.
public struct Generator {
    /// The style of indentation to use when generating the module map file
    public struct Indentation {
        public enum Style {
            case tabs
            case spaces(Int)
        }

        public let style: Style
        public let depth: Int
    }

    private let style: Indentation.Style

    public init(indentationStyle: Indentation.Style) {
        self.style = indentationStyle
    }

    /// Generate the contents of a module map file from the provided file node
    public func generateFileContents(with file: ModuleMapFile) -> String {
        let indentation = Indentation(style: style, depth: 0)
        return file.generate(with: indentation)
    }

    /// Generate the contents of a module map file and save it to the provided `fileURL`
    public func generateAndSave(file: ModuleMapFile, to fileURL: URL) throws {
        let fileContents = generateFileContents(with: file)
        try fileContents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

extension Generator.Indentation {
    var stringValue: String {
        switch style {
        case .tabs:
            return String(repeating: "\t", count: depth)
        case .spaces(let count):
            let totalSpaces = count * depth
            return String(repeating: " ", count: totalSpaces)
        }
    }

    func incrementDepth() -> Generator.Indentation {
        Generator.Indentation(style: style, depth: depth + 1)
    }
}

protocol Generating {
    func generate(with indentation: Generator.Indentation) -> String
}
