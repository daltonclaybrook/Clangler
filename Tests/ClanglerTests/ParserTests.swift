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

    func testEmptyModuleIsParsed() throws {
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

    func testExplicitFrameworkModuleIsParsed() throws {
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

    func testExternModuleIsParsed() throws {
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

    func testStandardHeaderIsParsed() throws {
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

    func testTextualHeaderIsParsed() throws {
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

    func testUmbrellaHeaderIsParsed() throws {
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

    func testExcludeHeaderIsParsed() throws {
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

    func testMultipleHeadersAreParsed() throws {
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

    func testUmbrellaDirectoryIsParsed() throws {
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

    func testSubmoduleIsParsed() throws {
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

    func testInferredSubmoduleIsParsed() throws {
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
}
