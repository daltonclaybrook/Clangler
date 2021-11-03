extension ModuleMapFile: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        let declarationStrings = moduleDeclarations.map { $0.generate(with: indentation) }
        return declarationStrings.joined(separator: "\n\n")
    }
}

extension ModuleDeclaration: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        switch self {
        case .local(let declaration):
            return declaration.generate(with: indentation)
        case .extern(let declaration):
            return declaration.generate(with: indentation)
        }
    }
}

extension LocalModuleDeclaration: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
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
        components.append(moduleId.generate(with: indentation))

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
    public func generate(with indentation: Generator.Indentation) -> String {
        let string = "extern module \(moduleId.generate(with: indentation)) \(filePath.quoted)"
        return indentation.stringValue + string
    }
}

extension ModuleId: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        dotSeparatedIdentifiers.joined(separator: ".")
    }
}

extension ModuleMember: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
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
            return "" // todo
        case .exportAs(let declaration):
            return "" // todo
        case .use(let declaration):
            return "" // todo
        case .link(let declaration):
            return "" // todo
        case .configMacros(let declaration):
            return "" // todo
        case .conflict(let declaration):
            return "" // todo
        }
    }
}

extension RequiresDeclaration: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        let featuresString = features
            .map { $0.generate(with: indentation) }
            .joined(separator: ", ")
        let string = "requires \(featuresString)"
        return indentation.stringValue + string
    }
}

extension Feature: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        let prefix = incompatible ? "!" : ""
        return prefix + identifier
    }
}

extension HeaderDeclaration: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
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
    public func generate(with indentation: Generator.Indentation) -> String {
        let string = "umbrella \(filePath.quoted)"
        return indentation.stringValue + string
    }
}

extension SubmoduleDeclaration: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        switch self {
        case .module(let declaration):
            return declaration.generate(with: indentation)
        case .inferred(let declaration):
            return declaration.generate(with: indentation)
        }
    }
}

extension InferredSubmoduleDeclaration: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
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
        components.append("*")

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

extension InferredSubmoduleMember: Generating {
    public func generate(with indentation: Generator.Indentation) -> String {
        indentation.stringValue + "export *"
    }
}

private extension String {
    /// Add quotes around the string
    var quoted: String {
        "\"\(self)\""
    }
}
