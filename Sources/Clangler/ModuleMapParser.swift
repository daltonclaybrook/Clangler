import Foundation

public final class ModuleMapParser {
    public enum Error: Swift.Error {
        case expectedTokenType(TokenType, token: Token)
        case expectedModuleDeclaration(Token?)
        case unexpectedToken(Token, message: String)
    }

    private let fileURL: URL
    private var currentTokenIndex: Int = 0
    private var tokens: [Token] = []

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func parse() throws -> ModuleMapFile {
        let lexer = try Lexer(fileURL: fileURL)
        currentTokenIndex = 0
        tokens = try lexer.scanAllTokens()
        return parseModuleMapFile()
    }

    // MARK: - Parser functions

    private func parseModuleMapFile() -> ModuleMapFile {
        var declarations: [ModuleDeclarationType] = []
        while currentTokenIndex < tokens.count {
            do {
                declarations.append(try parseModuleDeclaration())
            } catch let error {
                print("error: \(error)")
                synchronize()
            }
        }
        return ModuleMapFile(moduleDeclarations: declarations)
    }

    private func parseModuleDeclaration() throws -> ModuleDeclarationType {
        switch currentToken.type {
        case .keywordExplicit, .keywordFramework, .keywordModule:
            return try parseModule()
        case .keywordExtern:
            return try parseExternModule()
        default:
            throw Error.expectedModuleDeclaration(currentToken)
        }
    }

    private func parseModule() throws -> ModuleDeclaration {
        let explicit = match(type: .keywordExplicit)
        let framework = match(type: .keywordFramework)
        try consume(type: .keywordModule)
        let moduleId = try parseModuleId()
        let attributes = try parseAttributes()
        let members = try parseModuleMembersBlock()

        return ModuleDeclaration(
            explicit: explicit,
            framework: framework,
            moduleId: moduleId,
            attributes: attributes,
            members: members
        )
    }

    private func parseExternModule() throws -> ExternModuleDeclaration {
        try consume(type: .keywordExtern)
        try consume(type: .keywordModule)

        return ExternModuleDeclaration(
            moduleId: try parseModuleId(),
            filePath: try consume(type: .stringLiteral)
        )
    }

    private func parseModuleId() throws -> ModuleId {
        var identifiers = [try consume(type: .identifier)]
        while currentToken.type == .dot {
            identifiers.append(try consume(type: .identifier))
        }
        return ModuleId(dotSeparatedIdentifiers: identifiers)
    }

    private func parseAttributes() throws -> [Token] {
        var attributes: [Token] = []
        while !isAtEnd && match(type: .leadingBracket) {
            attributes.append(try consume(type: .identifier))
            try consume(type: .trailingBracket)
        }
        return attributes
    }

    private func parseModuleMembersBlock() throws -> [ModuleMember] {
        try consume(type: .leadingBrace)
        var members: [ModuleMember] = []
        while !isAtEnd && currentToken.type != .trailingBrace {
            members.append(try parseModuleMember())
        }
        return members
    }

    private func parseModuleMember() throws -> ModuleMember {
        if currentToken.type == .keywordRequires {
            return try parseRequiresDeclaration()
        } else if canParseHeaderDeclaration() {
            return try parseHeaderDeclaration()
        } else if currentToken.type == .keywordUmbrella {
            return try parseUmbrellaDirectoryDeclaration()
        } else {
            fatalError("implement remaining...")
        }
    }

    private func parseRequiresDeclaration() throws -> RequiresDeclaration {
        try consume(type: .keywordRequires)
        return RequiresDeclaration(features: try parseFeatureList())
    }

    private func parseFeatureList() throws -> [Feature] {
        var features = [try parseFeature()]
        while !isAtEnd && match(type: .comma) {
            features.append(try parseFeature())
        }
        return features
    }

    private func parseFeature() throws -> Feature {
        Feature(
            incompatible: match(type: .bang),
            identifier: try consume(type: .identifier)
        )
    }

    private func canParseHeaderDeclaration() -> Bool {
        switch currentToken.type {
        case .keywordPrivate,
             .keywordTextual,
             .keywordHeader,
             .keywordExclude:
            return true
        case .keywordUmbrella where peekNext()?.type == .keywordHeader:
            // If the current token is 'umbrella', it will be either an umbrella header
            // declaration or an umbrella directory declaration, so we check the next token.
            return true
        default:
            return false
        }
    }

    private func parseHeaderDeclaration() throws -> HeaderDeclaration {
        let kind = try parseHeaderKind()
        try consume(type: .keywordHeader)
        return HeaderDeclaration(
            kind: kind,
            filePath: try consume(type: .stringLiteral),
            headerAttributes: try parseHeaderAttributes()
        )
    }

    private func parseHeaderKind() throws -> HeaderDeclaration.Kind {
        if match(type: .keywordUmbrella) {
            return .umbrella
        } else if match(type: .keywordExclude) {
            return .exclude
        } else {
            let isPrivate = match(type: .keywordPrivate)
            let isTextual = match(type: .keywordTextual)
            return .normal(private: isPrivate, textual: isTextual)
        }
    }

    private func parseHeaderAttributes() throws -> [HeaderAttribute] {
        guard !isAtEnd && match(type: .leadingBrace) else { return [] }
        var attributes: [HeaderAttribute] = []
        while !isAtEnd && !match(type: .trailingBrace) {
            attributes.append(try parseHeaderAttribute())
        }
        return attributes
    }

    private func parseHeaderAttribute() throws -> HeaderAttribute {
        HeaderAttribute(
            key: try consume(type: .identifier),
            value: try consume(type: .integerLiteral)
        )
    }

    private func parseUmbrellaDirectoryDeclaration() throws -> UmbrellaDirectoryDeclaration {
        try consume(type: .keywordUmbrella)
        return UmbrellaDirectoryDeclaration(
            filePath: try consume(type: .stringLiteral)
        )
    }

    // MARK: - Helper functions

    private var currentToken: Token {
        isAtEnd ? tokens.last! : tokens[currentTokenIndex]
    }

    private var previousToken: Token {
        guard currentTokenIndex > 0 else {
            fatalError("Attempt to access token previous to the first one")
        }
        return tokens[currentTokenIndex - 1]
    }

    private var isAtEnd: Bool {
        currentTokenIndex >= tokens.count
    }

    private func peekNext() -> Token? {
        guard currentTokenIndex < tokens.count - 1 else { return nil }
        return tokens[currentTokenIndex + 1]
    }

    @discardableResult
    private func match(type: TokenType) -> Bool {
        guard !isAtEnd else { return false }
        if tokens[currentTokenIndex].type == type {
            currentTokenIndex += 1
            return true
        } else {
            return false
        }
    }

    @discardableResult
    private func consume(type: TokenType) throws -> Token {
        guard match(type: type) else {
            throw Error.expectedTokenType(type, token: currentToken)
        }
        return previousToken
    }

    private func advance() {
        guard !isAtEnd else { return }
        currentTokenIndex += 1
    }

    @discardableResult
    private func consumeEither(_ first: TokenType, _ second: TokenType) throws -> Token {
        switch currentToken.type {
        case first:
            return try consume(type: first)
        case second:
            return try consume(type: second)
        default:
            throw Error.expectedTokenType(first, token: currentToken)
        }
    }

    /// Advance up to the start of the next module declaration
    private func synchronize() {
        while !isAtEnd {
            switch currentToken.type {
            case .keywordExplicit, .keywordFramework, .keywordModule, .keywordExtern:
                return
            default:
                advance()
            }
        }
    }
}
