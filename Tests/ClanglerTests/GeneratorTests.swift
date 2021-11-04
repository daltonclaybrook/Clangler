import Clangler
import XCTest

final class GeneratorTests: XCTestCase {
    private var subject: Generator!

    override func setUp() {
        super.setUp()
        subject = Generator(indentationStyle: .spaces(4))
    }

    func testGeneratorOutputMatchesInput() throws {
        let contents = completeContents
        let result = Parser().parse(fileContents: contents)
        let file = try result.get()
        let exported = subject.generateFileContents(with: file)
        XCTAssertEqual(contents, exported)
    }

    // MARK: - Private helpers

    private var completeContents: String {
        """
        framework module MyLib [system] {
            umbrella header "MyLib.h"
            module Sub1 {
                requires objc, !blocks
                private header "Header1.h"
                textual header "Header2.h"
                umbrella header "Header3.h"
                exclude header "Header4.h"
                header "Header5.h" { size 123 mtime 456 }
            }
            module Sub2.Foo {
                umbrella "MyDirectory"
                export Fizz.Buzz.*
                export_as FooBar
                use Foo.Bar
            }
            module Sub3 {
                link framework "UIKit"
                link "z"
                config_macros [exhaustive] NDEBUG, LOG_LEVEL
                conflict OtherLib, "We don't like the other lib"
            }
            explicit framework module * [extern_c] {
                export *
            }
        }

        extern module ExternalLib "my_lib/module.modulemap"
        """
    }
}
