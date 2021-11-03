/// Utility used to generate module map file contents from an abstract syntax tree (AST)
/// representation. This is the reverse of `Parser`.
public struct Generator {
    public struct Indentation {
        public enum Style {
            case tabs
            case spaces(Int)
        }

        public let style: Style
        public let depth: Int
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

    func decrementDepth() -> Generator.Indentation {
        Generator.Indentation(style: style, depth: depth - 1)
    }
}

public protocol Generating {
    func generate(with indentation: Generator.Indentation) -> String
}
