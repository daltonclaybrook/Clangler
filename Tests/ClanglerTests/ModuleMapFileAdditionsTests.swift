import Clangler
import XCTest

final class ModuleMapFileAdditionsTests: XCTestCase {
    func testModuleIdIsInitializedFromStringLiteral() {
        let moduleId: ModuleId = "Foo.Bar"
        XCTAssertEqual(moduleId, ModuleId(dotSeparatedIdentifiers: ["Foo", "Bar"]))
    }

    func testModuleIdIsInitializedFromRawValue() {
        let moduleId = ModuleId(rawValue: "Foo.Bar.Fizz")
        XCTAssertEqual(moduleId, ModuleId(dotSeparatedIdentifiers: ["Foo", "Bar", "Fizz"]))
    }

    func testModuleIdRawValueIsCorrect() {
        let moduleId = ModuleId(dotSeparatedIdentifiers: ["Foo", "Bar"])
        XCTAssertEqual(moduleId.rawValue, "Foo.Bar")
    }

    func testModuleDeclarationReturnsCorrectModuleIdForLocal() {
        let localDeclaration = LocalModuleDeclaration(explicit: false, framework: false, moduleId: "Foo.Bar", attributes: [], members: [])
        let declaration = ModuleDeclaration.local(localDeclaration)
        XCTAssertEqual(declaration.moduleId, "Foo.Bar")
    }

    func testModuleDeclarationReturnsCorrectModuleIdForExtern() {
        let externDeclaration = ExternModuleDeclaration(moduleId: "Fizz", filePath: "Testing/module.modulemap")
        let declaration = ModuleDeclaration.extern(externDeclaration)
        XCTAssertEqual(declaration.moduleId, "Fizz")
    }
}
