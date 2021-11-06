public extension ModuleDeclaration {
    /// If this declaration is a local declaration, return the underlying associated value
    var local: LocalModuleDeclaration? {
        switch self {
        case .local(let declaration):
            return declaration
        case .extern:
            return nil
        }
    }

    /// If this declaration is an "extern" declaration, return the underlying associated value
    var extern: ExternModuleDeclaration? {
        switch self {
        case .extern(let declaration):
            return declaration
        case .local:
            return nil
        }
    }

    /// Get the module identifier for the declaration regardless if it is a local or extern declaration
    var moduleId: ModuleId {
        switch self {
        case .local(let declaration):
            return declaration.moduleId
        case .extern(let declaration):
            return declaration.moduleId
        }
    }
}

public extension ModuleMember {
    /// If this member is a "requires" declaration, return the underlying associated value
    var requires: RequiresDeclaration? {
        switch self {
        case .requires(let declaration):
            return declaration
        case .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is "header" declaration, return the underlying associated value
    var header: HeaderDeclaration? {
        switch self {
        case .header(let declaration):
            return declaration
        case .requires, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is an "umbrella directory" declaration, return the underlying associated value
    var umbrellaDirectory: UmbrellaDirectoryDeclaration? {
        switch self {
        case .umbrellaDirectory(let declaration):
            return declaration
        case .requires, .header, .submodule, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is a "submodule" declaration, return the underlying associated value
    var submodule: SubmoduleDeclaration? {
        switch self {
        case .submodule(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is an "export" declaration, return the underlying associated value
    var export: ExportDeclaration? {
        switch self {
        case .export(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is an "export as" declaration, return the underlying associated value
    var exportAs: ExportAsDeclaration? {
        switch self {
        case .exportAs(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is a "use" declaration, return the underlying associated value
    var use: UseDeclaration? {
        switch self {
        case .use(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .link, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is a "link" declaration, return the underlying associated value
    var link: LinkDeclaration? {
        switch self {
        case .link(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .configMacros, .conflict:
            return nil
        }
    }

    /// If this member is a "config macros" declaration, return the underlying associated value
    var configMacros: ConfigMacrosDeclaration? {
        switch self {
        case .configMacros(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .conflict:
            return nil
        }
    }

    /// If this member is a "conflict" declaration, return the underlying associated value
    var conflict: ConflictDeclaration? {
        switch self {
        case .conflict(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .configMacros:
            return nil
        }
    }
}

public extension SubmoduleDeclaration {
    /// If this submodule is a "module" declaration, return the underlying associated value
    var module: ModuleDeclaration? {
        switch self {
        case .module(let declaration):
            return declaration
        case .inferred:
            return nil
        }
    }

    /// If this submodule is an "inferred submodule" declaration, return the underlying associated value
    var inferred: InferredSubmoduleDeclaration? {
        switch self {
        case .inferred(let declaration):
            return declaration
        case .module:
            return nil
        }
    }
}

extension ModuleId: ExpressibleByStringLiteral, RawRepresentable {
    /// The raw string value of the module identifier
    public var rawValue: String {
        dotSeparatedIdentifiers.joined(separator: ".")
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(rawValue: String) {
        let components = rawValue.components(separatedBy: ".")
        self.init(dotSeparatedIdentifiers: components)
    }
}
