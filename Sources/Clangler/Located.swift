/// A value associated with a line and column in a file
@dynamicMemberLookup
public struct Located<T> {
    /// The value to associate with line and column numbers
    public private(set) var value: T
    /// The line number associated with the value
    public let line: Int
    /// The column number associated with the value
    public let column: Int

    public subscript<U>(dynamicMember keyPath: WritableKeyPath<T, U>) -> U {
        get { value[keyPath: keyPath] }
        set { value[keyPath: keyPath] = newValue }
    }

    /// Convert a `Located<T>` to a `Located<U>` by mapping over its `value`
    func map<U>(transform: (T) -> U) -> Located<U> {
        Located<U>(
            value: transform(value),
            line: line,
            column: column
        )
    }
}

extension Located: Error where T: Error {}
