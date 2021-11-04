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
}
