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
            return try parseNormalModule()
        case .keywordExtern:
            return try parseExternModule()
        default:
            throw Error.expectedModuleDeclaration(currentToken)
        }
    }

    private func parseNormalModule() throws -> ModuleDeclaration {
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
        } else if canParseSubmoduleDeclaration() {
            return try parseSubmoduleDeclaration()
        } else if currentToken.type == .keywordExport {
            return try parseExportDeclaration()
        } else if currentToken.type == .keywordExportAs {
            return try parseExportAsDeclaration()
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
        case .keywordUmbrella where peek(count: 1)?.type == .keywordHeader:
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

    private func canParseSubmoduleDeclaration() -> Bool {
        if willMatch(.keywordExplicit, .keywordFramework, .keywordModule)
            || willMatch(.keywordExplicit, .keywordModule)
            || willMatch(.keywordFramework, .keywordModule)
            || willMatch(.keywordExtern, .keywordModule)
            || willMatch(.keywordModule) {
            return true
        } else {
            return false
        }
    }

    private func parseSubmoduleDeclaration() throws -> SubmoduleDeclaration {
        // First, find the offset of the next module keyword
        var moduleOffset = 0
        while peek(count: moduleOffset)?.type != .keywordModule {
            moduleOffset += 1
        }

        // Check if the token right after the module keyword is a star. If so, this is an
        // inferred submodule declaration. Otherwise, it is a regular module declaration.
        if peek(count: moduleOffset + 1)?.type == .star {
            return .inferred(try parseInferredSubmoduleDeclaration())
        } else {
            return .module(try parseModuleDeclaration())
        }
    }

    private func parseInferredSubmoduleDeclaration() throws -> InferredSubmoduleDeclaration {
        let explicit = match(type: .keywordExplicit)
        let framework = match(type: .keywordFramework)
        try consume(type: .keywordModule)
        try consume(type: .star)

        return InferredSubmoduleDeclaration(
            explicit: explicit,
            framework: framework,
            attributes: try parseAttributes(),
            members: try parseInferredSubmoduleMemberBlock()
        )
    }

    private func parseInferredSubmoduleMemberBlock() throws -> [InferredSubmoduleMember] {
        try consume(type: .leadingBrace)
        var members: [InferredSubmoduleMember] = []
        while !isAtEnd && !match(type: .trailingBrace) {
            try consume(type: .keywordExport)
            try consume(type: .star)
            members.append(InferredSubmoduleMember())
        }
        return members
    }

    private func parseExportDeclaration() throws -> ExportDeclaration {
        try consume(type: .keywordExport)
        return ExportDeclaration(moduleId: try parseWildcardModuleId())
    }

    private func parseWildcardModuleId() throws -> WildcardModuleId {
        WildcardModuleId(
            dotSeparatedIdentifiers: try parseWildcardModuleIdComponents(),
            trailingStar: match(type: .star)
        )
    }

    private func parseWildcardModuleIdComponents() throws -> [Token] {
        if willMatch(.identifier, .dot) {
            let components = [try consume(type: .identifier)]
            try consume(type: .dot)
            return try components + parseWildcardModuleIdComponents()
        } else if willMatch(.identifier) {
            return [try consume(type: .identifier)]
        } else if willMatch(.star) {
            // parsed by caller
            return []
        } else {
            throw Error.unexpectedToken(currentToken, message: "Expected to match a wildcard module id component")
        }
    }

    private func parseExportAsDeclaration() throws -> ExportAsDeclaration {
        try consume(type: .keywordExportAs)
        return ExportAsDeclaration(identifier: try consume(type: .identifier))
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

    /// Return the token that is `count` ahead of the current token, or nil if no such token exists
    private func peek(count: Int = 0) -> Token? {
        guard currentTokenIndex < tokens.count - count else { return nil }
        return tokens[currentTokenIndex + count]
    }

    /// Returns true if the next several tokens will match the provided sequence of token types. This function
    /// does not advance the current token index.
    private func willMatch(_ types: TokenType...) -> Bool {
        for (type, offset) in zip(types, 0...) {
            let index = currentTokenIndex + offset
            guard index < tokens.count else { return false }
            guard tokens[index].type == type else { return false }
        }
        return true
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
