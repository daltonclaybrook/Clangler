protocol LocalModuleDeclarationType: Generating {
    associatedtype Member: Generating

    var explicit: Bool { get }
    var framework: Bool { get }
    var moduleIdString: String { get }
    var attributes: [String] { get }
    var members: [Member] { get }
}

extension LocalModuleDeclaration: LocalModuleDeclarationType {
    var moduleIdString: String {
        moduleId.rawValue
    }
}

extension InferredSubmoduleDeclaration: LocalModuleDeclarationType {
    var moduleIdString: String {
        "*"
    }
}
