@testable import Clangler
import XCTest

final class LocatedTests: XCTestCase {
    func testMapPreservesLineAndColumn() {
        let first = Located(value: "foo", line: 12, column: 34)
        let second = first.map { _ in 0 }
        XCTAssertEqual(Located(value: 0, line: first.line, column: first.column), second)
    }

    func testDynamicMemberLookupFieldsMatch() {
        struct Point {
            var x: Int
            var y: Int
        }
        let value = Point(x: 2, y: 3)
        var located = Located(value: value, line: 0, column: 0)
        XCTAssertEqual(located.x, 2)
        located.y = 10
        XCTAssertEqual(located.value.y, 10)
    }
}
