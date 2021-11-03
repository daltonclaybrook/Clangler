// Types in this file largely correspond to the grammar productions
// defined in the official Clang Modules document found here:
// https://clang.llvm.org/docs/Modules.html#module-map-language

/// Represents a complete module map file, which is a collection of declarations
public struct ModuleMapFile {
    /// The root-level module declarations in the file
    public let moduleDeclarations: [ModuleDeclaration]
}

/// Represents a module declaration, which can be a module that is defined locally
/// this the containing file, or externally in a referenced file
public enum ModuleDeclaration {
    /// A local module declaration
    case local(LocalModuleDeclaration)
    /// A reference to a module declared in another file
    case extern(ExternModuleDeclaration)
}

/// A module declared locally in the containing file
public struct LocalModuleDeclaration {
    /// Can only be applied to a submodule. The contents of explicit submodules are
    /// only made available when the submodule itself was explicitly named in an import
    /// declaration or was re-exported from an imported module.
    public let explicit: Bool
    /// Specifies that this module corresponds to a Darwin-style framework
    public let framework: Bool
    /// The identifier name of the module
    public let moduleId: ModuleId
    /// A collection of identifiers that describe specific behavior of other declarations
    public let attributes: [String]
    /// A collection of members of the module. There are many different kinds of members.
    public let members: [ModuleMember]
}

/// A module declared in a different file and merely referenced from the containing file
public struct ExternModuleDeclaration {
    /// The identifier name of the module
    public let moduleId: ModuleId
    /// The file where the module is declared. The file can be referenced either by an
    /// absolute path or by a path relative to the current map file.
    public let filePath: Token
}

/// The identifier name of a module
public struct ModuleId {
    /// The list of identifier strings that comprise the full identifier when dot-joined
    public let dotSeparatedIdentifiers: [String]
}

/// The various kinds of child members a module declaration can possess
public enum ModuleMember {
    /// Specifies the requirements that an importing translation unit must satisfy to use the module.
    case requires(RequiresDeclaration)
    /// Specifies that a particular header is associated with the enclosing module.
    case header(HeaderDeclaration)
    /// Specifies that all of the headers in the specified directory should be included within the module.
    case umbrellaDirectory(UmbrellaDirectoryDeclaration)
    /// Describes modules that are nested within their enclosing module.
    case submodule(SubmoduleDeclaration)
    /// Specifies which imported modules will automatically be re-exported as part of a given module’s API.
    case export(ExportDeclaration)
    /// Specifies that the current module will have its interface re-exported by the named module.
    case exportAs(ExportAsDeclaration)
    /// Specifies another module that the current top-level module intends to use.
    case use(UseDeclaration)
    /// Specifies a library or framework against which a program should be linked if the enclosing module
    /// is imported in any translation unit in that program.
    case link(LinkDeclaration)
    /// Specifies the set of configuration macros that have an effect on the API of the enclosing module.
    case configMacros(ConfigMacrosDeclaration)
    /// Describes a case where the presence of two different modules in the same translation unit is likely
    /// to cause a problem.
    case conflict(ConflictDeclaration)
}

/// Specifies the requirements that an importing translation unit must satisfy to use the module.
public struct RequiresDeclaration {
    /// The language dialects, platforms, environments and target specific features that must be
    /// present for the enclosing module to be accessible
    public let features: [Feature]
}

public struct Feature {
    /// If true, indicates that the feature is incompatible with the module
    public let incompatible: Bool
    /// The string identifier of the feature
    public let identifier: String
}

/// Specifies that a particular header is associated with the enclosing module.
public struct HeaderDeclaration {
    /// Indicates how the header contributes to the module
    public enum Kind {
        /// Indicates a header that contributes to the enclosing module. Specifically, when the
        /// module is built, the named header will be parsed and its declarations will be (logically)
        /// placed into the enclosing submodule.
        case standard(private: Bool)
        /// Indicates that the header will not be compiled when the module is built, and will be
        /// textually included if it is named by a #include directive. However, it is considered to be
        /// part of the module for the purpose of checking use-declarations, and must still be a
        /// lexically-valid header file.
        case textual(private: Bool)
        /// An umbrella header includes all of the headers within its directory (and any subdirectories),
        /// and is typically used (in the #include world) to easily access the full API provided by a
        /// particular library.
        case umbrella
        /// Indicates that the header will not be included when the module is built, nor will
        /// it be considered to be part of the module
        case exclude
    }

    /// Indicates how the header contributes to the module
    public let kind: Kind
    /// The file path of the header file
    public let filePath: String
    /// The use of header attributes avoids the need for Clang to speculatively `stat` every header
    /// referenced by a module map, but should typically only be used in machine-generated module maps
    public let headerAttributes: [HeaderAttribute]
}

/// The use of header attributes avoids the need for Clang to speculatively `stat` every header
/// referenced by a module map, but should typically only be used in machine-generated module maps
public struct HeaderAttribute {
    /// The attribute key identifier
    let key: String
    /// The attribute value integer
    let value: Int
}

/// Specifies that all of the headers in the specified directory should be included within the module.
public struct UmbrellaDirectoryDeclaration {
    /// The file path string of the umbrella directory
    public let filePath: String
}

/// Describes modules that are nested within their enclosing module.
public enum SubmoduleDeclaration {
    /// A standard module declaration
    case module(ModuleDeclaration)
    /// Describes a set of submodules that correspond to any headers that are part of the module
    /// but are not explicitly described by a header-declaration.
    case inferred(InferredSubmoduleDeclaration)
}

/// Describes a set of submodules that correspond to any headers that are part of the module
/// but are not explicitly described by a header-declaration.
public struct InferredSubmoduleDeclaration {
    /// The contents of explicit submodules are only made available when the submodule itself was
    /// explicitly named in an import declaration or was re-exported from an imported module.
    public let explicit: Bool
    /// Specifies that this module corresponds to a Darwin-style framework
    public let framework: Bool
    /// A collection of identifiers that describe specific behavior of other declarations
    public let attributes: [Token]
    /// A collection of members of the module
    public let members: [InferredSubmoduleMember]
}

/// A wildcard export declaration (i.e. `export *`)
public struct InferredSubmoduleMember {}

/// Specifies which imported modules will automatically be re-exported as part of a given module’s API.
public struct ExportDeclaration {
    /// The wildcard identifier indicating which modules will be re-exported
    public let moduleId: WildcardModuleId
}

/// A wildcard identifier indicating which modules will be re-exported
public struct WildcardModuleId {
    /// The list of string identifiers making up the prefix of a module identifier
    public let dotSeparatedIdentifiers: [String]
    /// Whether the module identifier is appended with a `*`, indicating a wildcard
    public let trailingStar: Bool
}

/// Specifies that the current module will have its interface re-exported by the named module.
public struct ExportAsDeclaration {
    /// The module that the current module will be re-exported through. Only top-level modules can
    /// be re-exported.
    public let identifier: String
}

/// Specifies another module that the current top-level module intends to use.
public struct UseDeclaration {
    /// The module to be used by the top-level module
    public let moduleID: ModuleId
}

/// Specifies a library or framework against which a program should be linked if the enclosing module
/// is imported in any translation unit in that program.
public struct LinkDeclaration {
    /// Whether the linker flag should take the form `-lMyLib` or `-framework MyFramework`
    public let framework: Bool
    /// The name of the library or framework to link
    public let libraryOrFrameworkName: String
}

/// Specifies the set of configuration macros that have an effect on the API of the enclosing module.
public struct ConfigMacrosDeclaration {
    /// Optional attributes used in the declaration
    public let attributes: [String]
    /// The list of names of the macros
    public let commaSeparatedMacroNames: [String]
}

/// Describes a case where the presence of two different modules in the same translation unit is likely
/// to cause a problem.
public struct ConflictDeclaration {
    /// Specifies the module with which the enclosing module conflicts
    public let moduleId: ModuleId
    /// A message to be provided as part of the compiler diagnostic when two modules conflict.
    public let diagnosticMessage: Token
}
