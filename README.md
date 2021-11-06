![Build Status](https://github.com/daltonclaybrook/Clangler/actions/workflows/swift.yml/badge.svg)
[![codecov](https://codecov.io/gh/daltonclaybrook/Clangler/branch/main/graph/badge.svg)](https://codecov.io/gh/daltonclaybrook/Clangler)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey)
[![License](https://img.shields.io/badge/license-MIT-blue)](https://github.com/daltonclaybrook/Clangler/blob/main/LICENSE.md)

**Clangler** is a Swift package used to parse [Clang module map](https://clang.llvm.org/docs/Modules.html) files into an abstract syntax tree (AST) representation. Once parsed, you can inspect or manipulate the nodes in the file, then generate and save a new file reflecting your changes.

## Examples

Find the names of all modules in a file:

```swift
func findAllTopLevelModuleNames(fileURL: URL) throws -> [String] {
    let moduleMap = try Parser().parseFile(at: fileURL).get()
    return moduleMap.moduleDeclarations.map(\.moduleId.rawValue)
}
```

Remove an existing umbrella header declaration and replace it with an umbrella directory:

```swift
func convertToUmbrellaDirectory(fileURL: URL) throws {
    var moduleMap = try Parser().parseFile(at: fileURL).get()

    // Find the module declaration and the existing umbrella header
    guard var declaration = moduleMap.moduleDeclarations.first?.local,
          let umbrellaHeaderMemberIndex = declaration.members
            .firstIndex(where: { $0.header?.kind == .umbrella })
    else { return }

    // Replace the umbrella header with an umbrella directory
    declaration.members[umbrellaHeaderMemberIndex] = .umbrellaDirectory(
        UmbrellaDirectoryDeclaration(filePath: "Headers")
    )

    // Replace the module declaration with the new one
    moduleMap.moduleDeclarations[0] = .local(declaration)

    // Save the modified file
    let generator = Generator(indentationStyle: .spaces(4))
    let newFileContents = generator.generateFileContents(with: moduleMap)
    try newFileContents.write(to: fileURL, atomically: true, encoding: .utf8)
}
```

Create a brand new module map from scratch instead of parsing one:

```swift
func buildModuleMapFromScratch(moduleName: String, headerPaths: [String]) throws {
    let moduleMap = ModuleMapFile(
        moduleDeclarations: [
            .local(LocalModuleDeclaration(
                explicit: false,
                framework: true,
                moduleId: ModuleId(rawValue: moduleName),
                attributes: [],
                members: headerPaths.map { filePath in
                    .header(HeaderDeclaration(
                        kind: .standard(private: false),
                        filePath: filePath,
                        headerAttributes: []
                    ))
                }
            ))
        ]
    )

    // Save the file
    let generator = Generator(indentationStyle: .spaces(4))
    let fileContents = generator.generateFileContents(with: moduleMap)
    let fileURL = URL(fileURLWithPath: "path/to/\(moduleName)/module.modulemap")
    try fileContents.write(to: fileURL, atomically: true, encoding: .utf8)
}
```

Discover syntax errors in a file:

```swift
func printAllSyntaxErrors(fileURL: URL) throws {
    let result = try Parser().parseFile(at: fileURL)
    guard case .failure(let syntaxErrors) = result else {
        return print("No syntax errors")
    }

    for error in syntaxErrors {
        print("line: \(error.line), column: \(error.column), description: \(error.description)")
    }
}
```

## Notable types

* [**Parser**](https://github.com/daltonclaybrook/Clangler/blob/main/Sources/Clangler/Parser.swift) — Used to parse the contents of a Clang module map file into an abstract syntax tree (AST) representation
* [**Lexer**](https://github.com/daltonclaybrook/Clangler/blob/main/Sources/Clangler/Lexer.swift) — Scans a module map string and produces tokens in the module map grammar. You will typically not instantiate this type directly as `Parser` uses it under the hood.
* [**Generator**](https://github.com/daltonclaybrook/Clangler/blob/main/Sources/Clangler/Generator.swift) — Used to generate module map file contents from an abstract syntax tree (AST) representation. This is the reverse of `Parser`.
* [**ModuleMapFile**](https://github.com/daltonclaybrook/Clangler/blob/main/Sources/Clangler/ModuleMapFile.swift) — The root node in the module map AST. This represents a complete module map file as a collection of declarations.

## Installation

In Xcode, you can add this package to your project by selecting File -> Swift Packages -> Add Package Dependency… Enter the Clangler GitHub URL and follow the prompts.

If you use a Package.swift file instead, add the following line inside of your package dependencies array:

```swift
.package(url: "https://github.com/daltonclaybrook/Clangler", from: "0.1.0"),
```

Now add Clangler as a dependency of any relevant targets:

```swift
.target(name: "MyApp", dependencies: ["Clangler"]),
```

## License

Clangler is available under the MIT license. See [LICENSE.md](https://github.com/daltonclaybrook/Clangler/blob/main/LICENSE.md) for more information.
