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

        let declarationLine = indentation.stringValue + components.joined(separator: " ")
        let membersLine = "" // todo: generate members
        let closingBraceLine = indentation.stringValue + "}"
        return [declarationLine, membersLine, closingBraceLine].joined(separator: "\n")
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

private extension String {
    /// Add quotes around the string
    var quoted: String {
        "\"\(self)\""
    }
}
