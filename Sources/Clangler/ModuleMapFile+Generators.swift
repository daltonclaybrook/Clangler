extension ModuleMapFile: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        let declarationStrings = moduleDeclarations.map { $0.generate(with: indentation) }
        return declarationStrings.joined(separator: "\n\n")
    }
}

extension ModuleDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        switch self {
        case .local(let declaration):
            return declaration.generate(with: indentation)
        case .extern(let declaration):
            return declaration.generate(with: indentation)
        }
    }
}

extension LocalModuleDeclarationType {
    func generate(with indentation: Generator.Indentation) -> String {
        let declarationLine = generateDeclarationLine(with: indentation)
        let membersString = generateMembers(with: indentation.incrementDepth())
        let closingBraceLine = indentation.stringValue + "}"
        return [declarationLine, membersString, closingBraceLine].joined(separator: "\n")
    }

    // MARK: Private helpers

    private func generateDeclarationLine(with indentation: Generator.Indentation) -> String {
        var components: [String] = []
        if explicit {
            components.append("explicit")
        }
        if framework {
            components.append("framework")
        }
        components.append("module")
        components.append(moduleIdString)

        let generatedAttributes = attributes.map { "[\($0)]" }
        components.append(contentsOf: generatedAttributes)
        components.append("{")

        return indentation.stringValue + components.joined(separator: " ")
    }

    private func generateMembers(with indentation: Generator.Indentation) -> String {
        let components = members.map { $0.generate(with: indentation)}
        return components.joined(separator: "\n")
    }
}

extension ExternModuleDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        let string = "extern module \(moduleId.generate(with: indentation)) \(filePath.quoted)"
        return indentation.stringValue + string
    }
}

extension ModuleId: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        dotSeparatedIdentifiers.joined(separator: ".")
    }
}

extension ModuleMember: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        switch self {
        case .requires(let declaration):
            return declaration.generate(with: indentation)
        case .header(let declaration):
            return declaration.generate(with: indentation)
        case .umbrellaDirectory(let declaration):
            return declaration.generate(with: indentation)
        case .submodule(let declaration):
            return declaration.generate(with: indentation)
        case .export(let declaration):
            return declaration.generate(with: indentation)
        case .exportAs(let declaration):
            return declaration.generate(with: indentation)
        case .use(let declaration):
            return declaration.generate(with: indentation)
        case .link(let declaration):
            return declaration.generate(with: indentation)
        case .configMacros(let declaration):
            return declaration.generate(with: indentation)
        case .conflict(let declaration):
            return declaration.generate(with: indentation)
        }
    }
}

extension RequiresDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        let featuresString = features
            .map { $0.generate(with: indentation) }
            .joined(separator: ", ")
        let string = "requires \(featuresString)"
        return indentation.stringValue + string
    }
}

extension Feature: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        let prefix = incompatible ? "!" : ""
        return prefix + identifier
    }
}

extension HeaderDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        var components: [String] = []
        switch kind {
        case .standard(let isPrivate):
            if isPrivate { components.append("private") }
        case .textual(let isPrivate):
            if isPrivate { components.append("private") }
            components.append("textual")
        case .umbrella:
            components.append("umbrella")
        case .exclude:
            components.append("exclude")
        }
        components.append("header")
        components.append(filePath.quoted)

        if let attributesComponent = generateHeaderAttributes() {
            components.append(attributesComponent)
        }
        return indentation.stringValue + components.joined(separator: " ")
    }

    // MARK: Private helpers

    private func generateHeaderAttributes() -> String? {
        var components = headerAttributes.map { "\($0.key) \($0.value)" }
        guard !components.isEmpty else { return nil }
        components.insert("{", at: 0)
        components.append("}")
        return components.joined(separator: " ")
    }
}

extension UmbrellaDirectoryDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        let string = "umbrella \(filePath.quoted)"
        return indentation.stringValue + string
    }
}

extension SubmoduleDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        switch self {
        case .module(let declaration):
            return declaration.generate(with: indentation)
        case .inferred(let declaration):
            return declaration.generate(with: indentation)
        }
    }
}

extension InferredSubmoduleMember: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        indentation.stringValue + "export *"
    }
}

extension ExportDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        indentation.stringValue + "export \(moduleId.generate(with: indentation))"
    }
}

extension WildcardModuleId: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        var components = dotSeparatedIdentifiers
        if trailingStar {
            components.append("*")
        }
        return components.joined(separator: ".")
    }
}

extension ExportAsDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        indentation.stringValue + "export_as \(identifier)"
    }
}

extension UseDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        indentation.stringValue + "use \(moduleID.generate(with: indentation))"
    }
}

extension LinkDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        var components = ["link"]
        if framework {
            components.append("framework")
        }
        components.append(libraryOrFrameworkName.quoted)
        return indentation.stringValue + components.joined(separator: " ")
    }
}

extension ConfigMacrosDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        var components = ["config_macros"]
        let generatedAttributes = attributes.map { "[\($0)]" }
        components.append(contentsOf: generatedAttributes)
        if !commaSeparatedMacroNames.isEmpty {
            let nameString = commaSeparatedMacroNames.joined(separator: ", ")
            components.append(nameString)
        }
        return indentation.stringValue + components.joined(separator: " ")
    }
}

extension ConflictDeclaration: Generating {
    func generate(with indentation: Generator.Indentation) -> String {
        let string = "conflict \(moduleId.generate(with: indentation)), \(diagnosticMessage.quoted)"
        return indentation.stringValue + string
    }
}

private extension String {
    /// Add quotes around the string
    var quoted: String {
        "\"\(self)\""
    }
}
