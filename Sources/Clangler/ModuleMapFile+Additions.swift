public extension ModuleDeclaration {
    var local: LocalModuleDeclaration? {
        switch self {
        case .local(let declaration):
            return declaration
        case .extern:
            return nil
        }
    }

    var extern: ExternModuleDeclaration? {
        switch self {
        case .extern(let declaration):
            return declaration
        case .local:
            return nil
        }
    }
}

public extension ModuleMember {
    var requires: RequiresDeclaration? {
        switch self {
        case .requires(let declaration):
            return declaration
        case .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    var header: HeaderDeclaration? {
        switch self {
        case .header(let declaration):
            return declaration
        case .requires, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    var umbrellaDirectory: UmbrellaDirectoryDeclaration? {
        switch self {
        case .umbrellaDirectory(let declaration):
            return declaration
        case .requires, .header, .submodule, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    var submodule: SubmoduleDeclaration? {
        switch self {
        case .submodule(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .export, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    var export: ExportDeclaration? {
        switch self {
        case .export(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .exportAs, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    var exportAs: ExportAsDeclaration? {
        switch self {
        case .exportAs(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .use, .link, .configMacros, .conflict:
            return nil
        }
    }

    var use: UseDeclaration? {
        switch self {
        case .use(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .link, .configMacros, .conflict:
            return nil
        }
    }

    var link: LinkDeclaration? {
        switch self {
        case .link(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .configMacros, .conflict:
            return nil
        }
    }

    var configMacros: ConfigMacrosDeclaration? {
        switch self {
        case .configMacros(let declaration):
            return declaration
        case .requires, .header, .umbrellaDirectory, .submodule, .export, .exportAs, .use, .link, .conflict:
            return nil
        }
    }

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
    var module: ModuleDeclaration? {
        switch self {
        case .module(let declaration):
            return declaration
        case .inferred:
            return nil
        }
    }

    var inferred: InferredSubmoduleDeclaration? {
        switch self {
        case .inferred(let declaration):
            return declaration
        case .module:
            return nil
        }
    }
}
