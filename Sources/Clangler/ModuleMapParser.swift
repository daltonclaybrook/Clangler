import Foundation

public struct ModuleMapParser {
    public enum Error: Swift.Error {
    }

    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    
}
