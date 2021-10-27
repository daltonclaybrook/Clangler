public enum TokenType {
    case dot // '.'
    case comma // ','
    case bang // '!'
    case star // '*'
    case leadingBrace // '{'
    case trailingBrace // '}'
    case leadingBracket // '['
    case trailingBracket // ']'
    case stringLiteral
    case integerLiteral
    case identifier
    case endOfFile
    case lexerError

    // Keywords

    case keywordConfigMacros
    case keywordExportAs
    case keywordPrivate
    case keywordConflict
    case keywordFramework
    case keywordRequires
    case keywordExclude
    case keywordHeader
    case keywordTextual
    case keywordExplicit
    case keywordLink
    case keywordUmbrella
    case keywordExtern
    case keywordModule
    case keywordUse
    case keywordExport
}

public extension TokenType {
    /// A mapping of reserved keywords to their token type
    static let tokenTypesForKeyword: [String: TokenType] = [
        "config_macros": keywordConfigMacros,
        "export_as": keywordExportAs,
        "private": keywordPrivate,
        "conflict": keywordConflict,
        "framework": keywordFramework,
        "requires": keywordRequires,
        "exclude": keywordExclude,
        "header": keywordHeader,
        "textual": keywordTextual,
        "explicit": keywordExplicit,
        "link": keywordLink,
        "umbrella": keywordUmbrella,
        "extern": keywordExtern,
        "module": keywordModule,
        "use": keywordUse,
        "export": keywordExport
    ]
}
