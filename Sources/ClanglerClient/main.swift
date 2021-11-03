import Clangler
import Foundation

let allNames = [
    "conflict",
    "inferred",
    "macros",
    "Realm",
    "require",
    "std"
]

let allFileURLs = allNames.map { name in
    URL(fileURLWithPath: "/Users/daltonclaybrook/Documents/Personal/Swift/Clangler/examples/\(name).modulemap")
}

let parser = Parser()
try allFileURLs.forEach { fileURL in
    let name = fileURL.lastPathComponent
    let result = try parser.parseFile(at: fileURL)

    switch result {
    case .success(let file):
        print("\(name): successfully parsed file with \(file.moduleDeclarations.count) declarations")
    case .failure(let errors):
        print("\(name): failed with \(errors.count) errors")
    }
}
