// Types in this file largely correspond to the grammar productions
// defined in the official Clang Modules document found here:
// https://clang.llvm.org/docs/Modules.html#module-map-language

/// Represents a complete module map file, which is a collection of declarations
public struct ModuleMapFile {
    /// The root-level module declarations in the file
    public var moduleDeclarations: [ModuleDeclaration]

    public init(moduleDeclarations: [ModuleDeclaration]) {
        self.moduleDeclarations = moduleDeclarations
    }
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
    public var explicit: Bool
    /// Specifies that this module corresponds to a Darwin-style framework
    public var framework: Bool
    /// The identifier name of the module
    public var moduleId: ModuleId
    /// A collection of identifiers that describe specific behavior of other declarations
    public var attributes: [String]
    /// A collection of members of the module. There are many different kinds of members.
    public var members: [ModuleMember]

    public init(
        explicit: Bool,
        framework: Bool,
        moduleId: ModuleId,
        attributes: [String],
        members: [ModuleMember]
    ) {
        self.explicit = explicit
        self.framework = framework
        self.moduleId = moduleId
        self.attributes = attributes
        self.members = members
    }
}

/// A module declared in a different file and merely referenced from the containing file
public struct ExternModuleDeclaration {
    /// The identifier name of the module
    public var moduleId: ModuleId
    /// The file where the module is declared. The file can be referenced either by an
    /// absolute path or by a path relative to the current map file.
    public var filePath: String

    public init(moduleId: ModuleId, filePath: String) {
        self.moduleId = moduleId
        self.filePath = filePath
    }
}

/// The identifier name of a module
public struct ModuleId {
    /// The list of identifier strings that comprise the full identifier when dot-joined
    public var dotSeparatedIdentifiers: [String]

    public init(dotSeparatedIdentifiers: [String]) {
        self.dotSeparatedIdentifiers = dotSeparatedIdentifiers
    }
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
    public var features: [Feature]

    public init(features: [Feature]) {
        self.features = features
    }
}

public struct Feature {
    /// If true, indicates that the feature is incompatible with the module
    public var incompatible: Bool
    /// The string identifier of the feature
    public var identifier: String

    public init(incompatible: Bool, identifier: String) {
        self.incompatible = incompatible
        self.identifier = identifier
    }
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
    public var kind: Kind
    /// The file path of the header file
    public var filePath: String
    /// The use of header attributes avoids the need for Clang to speculatively `stat` every header
    /// referenced by a module map, but should typically only be used in machine-generated module maps
    public var headerAttributes: [HeaderAttribute]

    public init(kind: Kind, filePath: String, headerAttributes: [HeaderAttribute]) {
        self.kind = kind
        self.filePath = filePath
        self.headerAttributes = headerAttributes
    }
}

/// The use of header attributes avoids the need for Clang to speculatively `stat` every header
/// referenced by a module map, but should typically only be used in machine-generated module maps
public struct HeaderAttribute {
    /// The attribute key identifier
    let key: String
    /// The attribute value integer
    let value: Int

    public init(key: String, value: Int) {
        self.key = key
        self.value = value
    }
}

/// Specifies that all of the headers in the specified directory should be included within the module.
public struct UmbrellaDirectoryDeclaration {
    /// The file path string of the umbrella directory
    public var filePath: String

    public init(filePath: String) {
        self.filePath = filePath
    }
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
    public var explicit: Bool
    /// Specifies that this module corresponds to a Darwin-style framework
    public var framework: Bool
    /// A collection of identifiers that describe specific behavior of other declarations
    public var attributes: [String]
    /// A collection of members of the module
    public var members: [InferredSubmoduleMember]

    public init(
        explicit: Bool,
        framework: Bool,
        attributes: [String],
        members: [InferredSubmoduleMember]
    ) {
        self.explicit = explicit
        self.framework = framework
        self.attributes = attributes
        self.members = members
    }
}

/// A wildcard export declaration (i.e. `export *`)
public struct InferredSubmoduleMember {
    public init() {}
}

/// Specifies which imported modules will automatically be re-exported as part of a given module’s API.
public struct ExportDeclaration {
    /// The wildcard identifier indicating which modules will be re-exported
    public var moduleId: WildcardModuleId

    public init(moduleId: WildcardModuleId) {
        self.moduleId = moduleId
    }
}

/// A wildcard identifier indicating which modules will be re-exported
public struct WildcardModuleId {
    /// The list of string identifiers making up the prefix of a module identifier
    public var dotSeparatedIdentifiers: [String]
    /// Whether the module identifier is appended with a `*`, indicating a wildcard
    public var trailingStar: Bool

    public init(dotSeparatedIdentifiers: [String], trailingStar: Bool) {
        self.dotSeparatedIdentifiers = dotSeparatedIdentifiers
        self.trailingStar = trailingStar
    }
}

/// Specifies that the current module will have its interface re-exported by the named module.
public struct ExportAsDeclaration {
    /// The module that the current module will be re-exported through. Only top-level modules can
    /// be re-exported.
    public var identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }
}

/// Specifies another module that the current top-level module intends to use.
public struct UseDeclaration {
    /// The module to be used by the top-level module
    public var moduleID: ModuleId

    public init(moduleID: ModuleId) {
        self.moduleID = moduleID
    }
}

/// Specifies a library or framework against which a program should be linked if the enclosing module
/// is imported in any translation unit in that program.
public struct LinkDeclaration {
    /// Whether the linker flag should take the form `-lMyLib` or `-framework MyFramework`
    public var framework: Bool
    /// The name of the library or framework to link
    public var libraryOrFrameworkName: String

    public init(framework: Bool, libraryOrFrameworkName: String) {
        self.framework = framework
        self.libraryOrFrameworkName = libraryOrFrameworkName
    }
}

/// Specifies the set of configuration macros that have an effect on the API of the enclosing module.
public struct ConfigMacrosDeclaration {
    /// Optional attributes used in the declaration
    public var attributes: [String]
    /// The list of names of the macros
    public var commaSeparatedMacroNames: [String]

    public init(attributes: [String], commaSeparatedMacroNames: [String]) {
        self.attributes = attributes
        self.commaSeparatedMacroNames = commaSeparatedMacroNames
    }
}

/// Describes a case where the presence of two different modules in the same translation unit is likely
/// to cause a problem.
public struct ConflictDeclaration {
    /// Specifies the module with which the enclosing module conflicts
    public var moduleId: ModuleId
    /// A message to be provided as part of the compiler diagnostic when two modules conflict.
    public var diagnosticMessage: String

    public init(moduleId: ModuleId, diagnosticMessage: String) {
        self.moduleId = moduleId
        self.diagnosticMessage = diagnosticMessage
    }
}
