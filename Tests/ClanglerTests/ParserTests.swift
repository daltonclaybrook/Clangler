import Clangler
import XCTest

final class ParserTests: XCTestCase {
    private var subject: Parser!

    override func setUp() {
        super.setUp()
        subject = Parser()
    }

    func testEmptyFileIsParsed() throws {
        let contents = ""
        let file = try subject.parse(fileContents: contents).get()
        XCTAssertEqual(file, ModuleMapFile(moduleDeclarations: []))
    }

    func testEmptyModuleDeclarationIsParsed() throws {
        let contents = "module MyLib {}"
        let file = try subject.parse(fileContents: contents).get()
        XCTAssertEqual(file.moduleDeclarations.count, 1)
        XCTAssertEqual(
            file.moduleDeclarations[0].local,
            LocalModuleDeclaration(
                explicit: false,
                framework: false,
                moduleId: ModuleId(dotSeparatedIdentifiers: ["MyLib"]),
                attributes: [],
                members: []
            )
        )
    }

    func testExplicitFrameworkModuleDeclarationIsParsed() throws {
        let contents = "explicit framework module MyLib {}"
        let file = try subject.parse(fileContents: contents).get()
        let declaration = file.moduleDeclarations.first?.local
        XCTAssertEqual(declaration?.explicit, true)
        XCTAssertEqual(declaration?.framework, true)
    }

    func testModuleAttributesAreParsed() throws {
        let contents = "module MyLib [system] [extern_c] {}"
        let file = try subject.parse(fileContents: contents).get()
        let declaration = file.moduleDeclarations.first?.local
        XCTAssertEqual(declaration?.attributes, ["system", "extern_c"])
    }

    func testExternModuleDeclarationIsParsed() throws {
        let contents = "extern module MyLib \"my_lib/module.modulemap\""
        let file = try subject.parse(fileContents: contents).get()
        XCTAssertEqual(file.moduleDeclarations.count, 1)
        XCTAssertEqual(
            file.moduleDeclarations[0].extern,
            ExternModuleDeclaration(
                moduleId: ModuleId(dotSeparatedIdentifiers: ["MyLib"]),
                filePath: "my_lib/module.modulemap"
            )
        )
    }

    func testModuleIdWithMultipleComponentsIsParsed() throws {
        let contents = "module MyLib.Foo.Bar {}"
        let file = try subject.parse(fileContents: contents).get()
        let moduleId = file.moduleDeclarations[0].local?.moduleId
        XCTAssertEqual(
            moduleId,
            ModuleId(dotSeparatedIdentifiers: ["MyLib", "Foo", "Bar"])
        )
    }

    func testRequiresDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            requires objc, !blocks
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].requires,
            RequiresDeclaration(
                features: [
                    Feature(incompatible: false, identifier: "objc"),
                    Feature(incompatible: true, identifier: "blocks")
                ]
            )
        )
    }

    func testStandardHeaderDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            private header "MyLib.h"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].header,
            HeaderDeclaration(
                kind: .standard(private: true),
                filePath: "MyLib.h",
                headerAttributes: []
            )
        )
    }

    func testTextualHeaderDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            textual header "MyLib.h"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].header,
            HeaderDeclaration(
                kind: .textual(private: false),
                filePath: "MyLib.h",
                headerAttributes: []
            )
        )
    }

    func testUmbrellaHeaderDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            umbrella header "MyLib.h"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].header,
            HeaderDeclaration(
                kind: .umbrella,
                filePath: "MyLib.h",
                headerAttributes: []
            )
        )
    }

    func testExcludeHeaderDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            exclude header "MyLib.h"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].header,
            HeaderDeclaration(
                kind: .exclude,
                filePath: "MyLib.h",
                headerAttributes: []
            )
        )
    }

    func testHeaderAttributesAreParsed() throws {
        let contents = """
        module MyLib {
            header "MyLib.h" { size 123 mtime 456 }
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        let attributes = members[0].header?.headerAttributes ?? []
        XCTAssertEqual(attributes, [
            HeaderAttribute(key: "size", value: 123),
            HeaderAttribute(key: "mtime", value: 456)
        ])
    }

    func testMultipleHeaderDeclarationsAreParsed() throws {
        let contents = """
        module MyLib {
            header "MyLib.h"
            header "OtherHeader.h"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let headerFiles = file.moduleDeclarations[0].local?.members
            .compactMap(\.header)
            .map(\.filePath) ?? []
        XCTAssertEqual(headerFiles, ["MyLib.h", "OtherHeader.h"])
    }

    func testUmbrellaDirectoryDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            umbrella "MyDirectory"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].umbrellaDirectory,
            UmbrellaDirectoryDeclaration(filePath: "MyDirectory")
        )
    }

    func testSubmoduleDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            explicit module MySubLib.Foo {
                private header "MySubLib.h"
            }
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].submodule?.module?.local,
            LocalModuleDeclaration(
                explicit: true,
                framework: false,
                moduleId: ModuleId(dotSeparatedIdentifiers: ["MySubLib", "Foo"]),
                attributes: [],
                members: [
                    .header(HeaderDeclaration(kind: .standard(private: true), filePath: "MySubLib.h", headerAttributes: []))
                ]
            )
        )
    }

    func testInferredSubmoduleDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            explicit framework module * [system] {
                export *
            }
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].submodule?.inferred,
            InferredSubmoduleDeclaration(
                explicit: true,
                framework: true,
                attributes: ["system"],
                members: [ InferredSubmoduleMember() ]
            )
        )
    }

    func testExportDeclarationsAreParsed() throws {
        let contents = """
        module MyLib {
            export *
            export Foo
            export Bar.Baz
            export Fizz.Buzz.*
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members
            .compactMap(\.export)
            .map(\.moduleId) ?? []
        XCTAssertEqual(members, [
            WildcardModuleId(
                dotSeparatedIdentifiers: [],
                trailingStar: true
            ),
            WildcardModuleId(
                dotSeparatedIdentifiers: ["Foo"],
                trailingStar: false
            ),
            WildcardModuleId(
                dotSeparatedIdentifiers: ["Bar", "Baz"],
                trailingStar: false
            ),
            WildcardModuleId(
                dotSeparatedIdentifiers: ["Fizz", "Buzz"],
                trailingStar: true
            )
        ])
    }

    func testExportAsDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            export_as FooBar
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].exportAs,
            ExportAsDeclaration(identifier: "FooBar")
        )
    }

    func testUseDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            use Foo.Bar
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].use,
            UseDeclaration(
                moduleID: ModuleId(dotSeparatedIdentifiers: ["Foo", "Bar"])
            )
        )
    }

    func testLinkDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            link framework "UIKit"
            link "z"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members
            .compactMap(\.link) ?? []
        XCTAssertEqual(members, [
            LinkDeclaration(framework: true, libraryOrFrameworkName: "UIKit"),
            LinkDeclaration(framework: false, libraryOrFrameworkName: "z")
        ])
    }

    func testConfigMacrosDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            config_macros
            config_macros NDEBUG
            config_macros [exhaustive] NDEBUG, LOG_LEVEL
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members
            .compactMap(\.configMacros) ?? []
        XCTAssertEqual(members, [
            ConfigMacrosDeclaration(
                attributes: [],
                commaSeparatedMacroNames: []
            ),
            ConfigMacrosDeclaration(
                attributes: [],
                commaSeparatedMacroNames: ["NDEBUG"]
            ),
            ConfigMacrosDeclaration(
                attributes: ["exhaustive"],
                commaSeparatedMacroNames: ["NDEBUG", "LOG_LEVEL"]
            )
        ])
    }

    func testConflictDeclarationIsParsed() throws {
        let contents = """
        module MyLib {
            conflict OtherLib, "We don't like the other lib"
        }
        """
        let file = try subject.parse(fileContents: contents).get()
        let members = file.moduleDeclarations[0].local?.members ?? []
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(
            members[0].conflict,
            ConflictDeclaration(
                moduleId: ModuleId(dotSeparatedIdentifiers: ["OtherLib"]),
                diagnosticMessage: "We don't like the other lib"
            )
        )
    }

    // MARK: - Error tests

    func testInvalidModuleDeclarationThrowsError() throws {
        let contents = """
        module MyLib {
            oops
        }
        """
        let errors = try XCTUnwrap(subject.parse(fileContents: contents).failure).map(\.value)
        XCTAssertEqual(errors, [
            ParseError.unexpectedToken(.identifier, lexeme: "oops", message: "Expected a module member declaration")
        ])
    }

    func testInvalidIntegerThrowsError() throws {
        let overflow = "19223372036854775807"
        let contents = """
        module MyLib {
            header "MyLib.h" { size \(overflow) }
        }
        """
        let errors = try XCTUnwrap(subject.parse(fileContents: contents).failure).map(\.value)
        XCTAssertEqual(errors, [
            ParseError.failedToMakeIntegerFromLexeme(overflow)
        ])
    }

    func testInvalidWildcardModuleIdThrowsError() throws {
        let contents = """
        module MyLib {
            export "literal"
        }
        """
        let errors = try XCTUnwrap(subject.parse(fileContents: contents).failure).map(\.value)
        XCTAssertEqual(errors, [
            ParseError.unexpectedToken(.stringLiteral, lexeme: "\"literal\"", message: "Expected a wildcard module identifier component")
        ])
    }

    func testMissingTrailingBraceInModuleThrowsError() throws {
        let contents = """
        module MyLib {
            header "MyLib.h"
        """
        let errors = try XCTUnwrap(subject.parse(fileContents: contents).failure).map(\.value)
        XCTAssertEqual(errors, [
            ParseError.unexpectedToken(.endOfFile, lexeme: "", message: "Expected '}' after module members block")
        ])
    }
}

extension Result {
    var failure: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
