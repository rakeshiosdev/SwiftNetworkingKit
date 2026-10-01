import Foundation

/// A case-insensitive wrapper for HTTP headers.
public struct HTTPHeaders: Sendable, Equatable, ExpressibleByDictionaryLiteral, Sequence {
    private var dictionary: [String: (name: String, value: String)]

    public init() {
        self.dictionary = [:]
    }

    public init(_ dictionary: [String: String]) {
        self.dictionary = [:]
        for (key, value) in dictionary {
            self.dictionary[key.lowercased()] = (name: key, value: value)
        }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.dictionary = [:]
        for (key, value) in elements {
            self.dictionary[key.lowercased()] = (name: key, value: value)
        }
    }

    public subscript(name: String) -> String? {
        get {
            dictionary[name.lowercased()]?.value
        }
        set {
            if let newValue {
                dictionary[name.lowercased()] = (name: name, value: newValue)
            } else {
                dictionary.removeValue(forKey: name.lowercased())
            }
        }
    }

    public mutating func add(name: String, value: String) {
        self[name] = value
    }

    public mutating func remove(name: String) {
        self[name] = nil
    }

    public mutating func merge(_ other: HTTPHeaders) {
        for (key, value) in other {
            self[key] = value
        }
    }

    public func merging(_ other: HTTPHeaders) -> HTTPHeaders {
        var result = self
        result.merge(other)
        return result
    }

    /// Returns a dictionary of headers with string keys and values.
    public var rawDictionary: [String: String] {
        var dict: [String: String] = [:]
        for (_, pair) in dictionary {
            dict[pair.name] = pair.value
        }
        return dict
    }

    public func makeIterator() -> IndexingIterator<[(key: String, value: String)]> {
        let pairs = dictionary.values.map { (key: $0.name, value: $0.value) }
        return pairs.makeIterator()
    }

    public static func == (lhs: HTTPHeaders, rhs: HTTPHeaders) -> Bool {
        lhs.dictionary.mapValues { $0.value } == rhs.dictionary.mapValues { $0.value }
    }
}
