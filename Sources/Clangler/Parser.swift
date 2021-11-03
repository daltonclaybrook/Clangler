import Foundation

/// A utility used to parse the contents of a Clang module map file into an abstract syntax
/// tree (AST) representation.
public final class Parser {
    private let lexer: LexerType
    private var currentTokenIndex: Int = 0
    private var tokens: [Token] = []
    private var errors: [Located<ParseError>] = []

    public init(lexer: LexerType = Lexer()) {
        self.lexer = lexer
    }

    public func parseFile(at url: URL) throws -> Result<ModuleMapFile, [Located<ParseError>]> {
        let fileContents = try String(contentsOf: url)
        return parse(fileContents: fileContents)
    }

    public func parse(fileContents: String) -> Result<ModuleMapFile, [Located<ParseError>]> {
        (tokens, errors) = lexer.scanAllTokens(fileContents: fileContents)
        currentTokenIndex = 0

        precondition(!tokens.isEmpty, "The returned tokens array should never be empty")
        precondition(tokens.last?.type == .endOfFile, "The returned tokens array must be terminated by an `.endOfFile` token")
        return parseModuleMapFile()
    }

    // MARK: - Parser functions

    private func parseModuleMapFile() -> Result<ModuleMapFile, [Located<ParseError>]> {
        var declarations: [ModuleDeclaration] = []
        while !isAtEnd {
            do {
                declarations.append(try parseModuleDeclaration())
            } catch let error as ParseError {
                emitError(error)
                synchronize()
            } catch let error {
                assertionFailure("Unhandled error: \(error.localizedDescription)")
                synchronize()
            }
        }

        if errors.isEmpty {
            return .success(ModuleMapFile(moduleDeclarations: declarations))
        } else {
            return .failure(errors)
        }
    }

    private func parseModuleDeclaration() throws -> ModuleDeclaration {
        switch currentToken.type {
        case .keywordExtern:
            return .extern(try parseExternModule())
        default:
            return .local(try parseLocalModule())
        }
    }

    private func parseLocalModule() throws -> LocalModuleDeclaration {
        let explicit = match(type: .keywordExplicit)
        let framework = match(type: .keywordFramework)
        try consume(type: .keywordModule, message: "Expected 'module' declaration")

        return LocalModuleDeclaration(
            explicit: explicit,
            framework: framework,
            moduleId: try parseModuleId(),
            attributes: try parseAttributes(),
            members: try parseModuleMembersBlock()
        )
    }

    private func parseExternModule() throws -> ExternModuleDeclaration {
        try consume(type: .keywordExtern, message: "Expected 'extern' keyword")
        try consume(type: .keywordModule, message: "Expected 'module' keyword")
        let moduleId = try parseModuleId()
        let filePathToken = try consume(type: .stringLiteral, message: "Expected file path string literal")

        return ExternModuleDeclaration(
            moduleId: moduleId,
            filePath: filePathToken.stringLiteralValue
        )
    }

    private func parseModuleId() throws -> ModuleId {
        let identifierToken = try consume(type: .identifier, message: "Expected module identifier")
        var identifiers = [identifierToken.lexeme]
        while match(type: .dot) {
            let token = try consume(type: .identifier, message: "Expected module identifier component")
            identifiers.append(token.lexeme)
        }
        return ModuleId(dotSeparatedIdentifiers: identifiers)
    }

    private func parseAttributes() throws -> [String] {
        var attributes: [String] = []
        while !isAtEnd && match(type: .leadingBracket) {
            let attributeToken = try consume(type: .identifier, message: "Expected attribute identifier")
            attributes.append(attributeToken.lexeme)
            try consume(type: .trailingBracket, message: "Expected ']' after attribute")
        }
        return attributes
    }

    private func parseModuleMembersBlock() throws -> [ModuleMember] {
        try consume(type: .leadingBrace, message: "Expected '{' after module declaration")
        var members: [ModuleMember] = []
        while !isAtEnd && currentToken.type != .trailingBrace {
            members.append(try parseModuleMember())
        }
        try consume(type: .trailingBrace, message: "Expected '}' after module members block")
        return members
    }

    private func parseModuleMember() throws -> ModuleMember {
        if canParseHeaderDeclaration() {
            return .header(try parseHeaderDeclaration())
        } else if canParseSubmoduleDeclaration() {
            return .submodule(try parseSubmoduleDeclaration())
        }

        switch currentToken.type {
        case .keywordRequires:
            return .requires(try parseRequiresDeclaration())
        case .keywordUmbrella:
            return .umbrellaDirectory(try parseUmbrellaDirectoryDeclaration())
        case .keywordExport:
            return .export(try parseExportDeclaration())
        case .keywordExportAs:
            return .exportAs(try parseExportAsDeclaration())
        case .keywordUse:
            return .use(try parseUseDeclaration())
        case .keywordLink:
            return .link(try parseLinkDeclaration())
        case .keywordConfigMacros:
            return .configMacros(try parseConfigMacrosDeclaration())
        case .keywordConflict:
            return .conflict(try parseConflictDeclaration())
        default:
            throw ParseError.unexpectedToken(currentToken.type, lexeme: currentToken.lexeme, message: "Expected a module member declaration")
        }
    }

    private func parseRequiresDeclaration() throws -> RequiresDeclaration {
        try consume(type: .keywordRequires, message: "Expected 'requires' keyword")
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
        let incompatible = match(type: .bang)
        let identifierToken = try consume(type: .identifier, message: "Expected feature identifier")
        return Feature(
            incompatible: incompatible,
            identifier: identifierToken.lexeme
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
        try consume(type: .keywordHeader, message: "Expected 'header' declaration")
        let filePathToken = try consume(type: .stringLiteral, message: "Expected file path string literal")
        return HeaderDeclaration(
            kind: kind,
            filePath: filePathToken.stringLiteralValue,
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
            if isTextual {
                return .textual(private: isPrivate)
            } else {
                return .standard(private: isPrivate)
            }
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
        let keyToken = try consume(type: .identifier, message: "Expected header attribute key identifier")
        let valueToken = try consume(type: .integerLiteral, message: "Expected header attribute value integer")
        guard let value = Int(valueToken.lexeme) else {
            throw ParseError.failedToMakeIntegerFromLexeme(valueToken.lexeme)
        }

        return HeaderAttribute(
            key: keyToken.lexeme,
            value: value
        )
    }

    private func parseUmbrellaDirectoryDeclaration() throws -> UmbrellaDirectoryDeclaration {
        try consume(type: .keywordUmbrella, message: "Expected 'umbrella' keyword")
        let filePathToken = try consume(type: .stringLiteral, message: "Expected file path string literal")
        return UmbrellaDirectoryDeclaration(
            filePath: filePathToken.stringLiteralValue
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
        // First, find the offset of the next module keyword. We know it exists because
        // we've already called `canParseSubmoduleDeclaration()`. At most, it's two tokens away.
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
        try consume(type: .keywordModule, message: "Expected 'module' declaration")
        try consume(type: .star, message: "Expected '*' symbol")

        return InferredSubmoduleDeclaration(
            explicit: explicit,
            framework: framework,
            attributes: try parseAttributes(),
            members: try parseInferredSubmoduleMemberBlock()
        )
    }

    private func parseInferredSubmoduleMemberBlock() throws -> [InferredSubmoduleMember] {
        try consume(type: .leadingBrace, message: "Expected '{' after module declaration")
        var members: [InferredSubmoduleMember] = []
        while !isAtEnd && currentToken.type != .trailingBrace {
            try consume(type: .keywordExport, message: "Expected 'export' keyword")
            try consume(type: .star, message: "Expected '*' symbol")
            members.append(InferredSubmoduleMember())
        }
        try consume(type: .trailingBrace, message: "Expected '}' after module members block")
        return members
    }

    private func parseExportDeclaration() throws -> ExportDeclaration {
        try consume(type: .keywordExport, message: "Expected 'export' keyword")
        return ExportDeclaration(moduleId: try parseWildcardModuleId())
    }

    private func parseWildcardModuleId() throws -> WildcardModuleId {
        WildcardModuleId(
            dotSeparatedIdentifiers: try parseWildcardModuleIdComponents(),
            trailingStar: match(type: .star)
        )
    }

    private func parseWildcardModuleIdComponents() throws -> [String] {
        if willMatch(.identifier, .dot) {
            let componentToken = try consume(type: .identifier, message: "Expected identifier")
            let components = [componentToken.lexeme]
            try consume(type: .dot, message: "Expected '.' symbol")
            return try components + parseWildcardModuleIdComponents()
        } else if willMatch(.identifier) {
            let componentToken = try consume(type: .identifier, message: "Expected identifier")
            return [componentToken.lexeme]
        } else if willMatch(.star) {
            // parsed by caller
            return []
        } else {
            throw ParseError.unexpectedToken(currentToken.type, lexeme: currentToken.lexeme, message: "Expected a wildcard module identifier component")
        }
    }

    private func parseExportAsDeclaration() throws -> ExportAsDeclaration {
        try consume(type: .keywordExportAs, message: "Expected 'export_as' keyword")
        let identifierToken = try consume(type: .identifier, message: "Expected module name identifier")
        return ExportAsDeclaration(
            identifier: identifierToken.lexeme
        )
    }

    private func parseUseDeclaration() throws -> UseDeclaration {
        try consume(type: .keywordUse, message: "Expected 'use' keyword")
        return UseDeclaration(moduleID: try parseModuleId())
    }

    private func parseLinkDeclaration() throws -> LinkDeclaration {
        try consume(type: .keywordLink, message: "Expected 'link' keyword")
        let isFramework = match(type: .keywordFramework)
        let nameToken = try consume(type: .stringLiteral, message: "Expected library or framework name string literal")
        return LinkDeclaration(
            framework: isFramework,
            libraryOrFrameworkName: nameToken.stringLiteralValue
        )
    }

    private func parseConfigMacrosDeclaration() throws -> ConfigMacrosDeclaration {
        try consume(type: .keywordConfigMacros, message: "Expected 'config_macros' keyword")
        return ConfigMacrosDeclaration(
            attributes: try parseAttributes(),
            commaSeparatedMacroNames: try parseConfigMacroList()
        )
    }

    private func parseConfigMacroList() throws -> [String] {
        guard willMatch(.identifier) else { return [] }

        let macroToken = try consume(type: .identifier, message: "Expected macro identifier")
        var identifiers = [macroToken.lexeme]
        while !isAtEnd && match(type: .comma) {
            let macroToken = try consume(type: .identifier, message: "Expected macro identifier")
            identifiers.append(macroToken.lexeme)
        }
        return identifiers
    }

    private func parseConflictDeclaration() throws -> ConflictDeclaration {
        try consume(type: .keywordConflict, message: "Expected 'conflict' keyword")
        let moduleId = try parseModuleId()
        try consume(type: .comma, message: "Expected ',' symbol")
        let messageToken = try consume(type: .stringLiteral, message: "Expected diagnostic message string literal")

        return ConflictDeclaration(
            moduleId: moduleId,
            diagnosticMessage: messageToken.stringLiteralValue
        )
    }

    // MARK: - Helper functions

    private var currentToken: Token {
        precondition(currentTokenIndex < tokens.count, "Token index out of bounds")
        return tokens[currentTokenIndex]
    }

    private var previousToken: Token {
        precondition(currentTokenIndex > 0, "Attempt to access token previous to the first one")
        return tokens[currentTokenIndex - 1]
    }

    private var isAtEnd: Bool {
        tokens[currentTokenIndex].type == .endOfFile
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
    private func consume(type: TokenType, message: String) throws -> Token {
        guard match(type: type) else {
            throw ParseError.unexpectedToken(currentToken.type, lexeme: currentToken.lexeme, message: message)
        }
        return previousToken
    }

    private func emitError(_ error: ParseError) {
        errors.append(
            Located(value: error, line: currentToken.line, column: currentToken.column)
        )
    }

    /// Advance up to the start of the next module declaration
    private func synchronize() {
        while !isAtEnd {
            switch currentToken.type {
            case .keywordExplicit, .keywordModule, .keywordExtern:
                return
            case .keywordFramework where peek(count: 1)?.type == .keywordModule:
                // Only return if part of a module declaration
                return
            default:
                currentTokenIndex += 1
            }
        }
    }
}
