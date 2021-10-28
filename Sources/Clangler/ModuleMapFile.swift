public struct ModuleMapFile {
    public let moduleDeclarations: [ModuleDeclaration]
}

public struct ModuleDeclaration {
    public let explicit: Bool
    public let framework: Bool
    public let moduleId: ModuleId
    public let attributes: [Token]
    public let members: [ModuleMember]
}

public struct ExternModuleDeclaration {
    public let moduleId: ModuleId
    public let filePath: Token
}

public struct ModuleId {
    public let dotSeparatedIdentifiers: [Token]
}

public protocol ModuleMember {}

public struct RequiresDeclaration: ModuleMember {
    public let features: [Feature]
}

public struct Feature {
    /// If true, indicates that the feature is incompatible with the module
    public let incompatible: Bool
    public let identifier: Token
}

public struct HeaderDeclaration: ModuleMember {
    public enum Kind {
        case normal(private: Bool, textual: Bool)
        case umbrella
        case exclude
    }

    public let kind: Kind
    public let filePath: Token
    public let headerAttributes: [HeaderAttribute]
}

public enum HeaderAttribute {
    case size(Token)
    case mtime(Token)
}

public struct UmbrellaDirectoryDeclaration: ModuleMember {
    public let filePath: Token
}

public enum SubmoduleDeclaration: ModuleMember {
    case module(ModuleDeclaration)
    case inferred(InferredSubmoduleDeclaration)
}

public struct InferredSubmoduleDeclaration {
    public let explicit: Bool
    public let framework: Bool
    public let attributes: [Token]
    public let members: [InferredSubmoduleMember]
}

public struct InferredSubmoduleMember {}

public struct ExportDeclaration: ModuleMember {
    public let moduleId: WildcardModuleId
}

public struct WildcardModuleId {
    public let dotSeparatedIdentifiers: [Token]
    public let trailingStar: Bool
}

public struct ExportAsDeclaration: ModuleMember {
    public let identifier: Token
}

public struct UseDeclaration: ModuleMember {
    public let moduleID: ModuleId
}

public struct LinkDeclaration: ModuleMember {
    public let framework: Bool
    public let libraryOrFrameworkName: Token
}

public struct ConfigMacrosDeclaration: ModuleMember {
    public let attributes: [Token]
    public let commaSeparatedMacroNames: [Token]
}

public struct ConflictDeclaration: ModuleMember {
    public let moduleId: ModuleId
    public let diagnosticMessage: Token
}