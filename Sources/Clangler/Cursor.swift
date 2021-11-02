/// A convenience utility for scanning the contents of a string and preserving line/column numbers
public struct Cursor {
    public let string: String
    public private(set) var currentIndex: String.Index

    public private(set) var currentLine = 1
    public private(set) var currentColumn = 1

    public var isAtEnd: Bool {
        currentIndex >= string.endIndex
    }

    /// The previously scanned character
    public var previous: Character {
        guard currentIndex > string.startIndex else { return "\0" }
        return string[string.index(before: currentIndex)]
    }

    public init(string: String) {
        guard !string.isEmpty else {
            fatalError("Attempted to initialize Cursor with empty string")
        }

        self.string = string
        self.currentIndex = string.startIndex
    }

    /// Advance the current index and return the next character
    @discardableResult
    public mutating func advance() -> Character {
        guard !isAtEnd else {
            fatalError("Attempted to advance while already past the end of the string")
        }

        let current = string[currentIndex]
        currentIndex = string.index(after: currentIndex)
        advanceLineAndColumn(for: current)
        return current
    }

    /// If the next scanned character matches the provided character, advance the cursor and return
    /// `true`. Otherwise, do not advance the scanner and return `false`.
    public mutating func match(next: Character) -> Bool {
        guard !isAtEnd else { return false }

        let current = string[currentIndex]
        guard current == next else { return false }

        currentIndex = string.index(after: currentIndex)
        advanceLineAndColumn(for: current)
        return true
    }

    /// Return the next character in the string without advancing the current index
    public func peek() -> Character {
        guard !isAtEnd else { return "\0" }
        return string[currentIndex]
    }

    // MARK: - Private helpers

    private mutating func advanceLineAndColumn(for next: Character) {
        if next.isNewline {
            currentLine += 1
            currentColumn = 1
        } else {
            currentColumn += 1
        }
    }
}
