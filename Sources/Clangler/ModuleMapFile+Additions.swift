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
