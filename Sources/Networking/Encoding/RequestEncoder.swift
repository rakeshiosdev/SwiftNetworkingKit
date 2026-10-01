import Foundation

/// Protocol for encoding request bodies.
public protocol RequestEncoder: Sendable {
    func encode<T: Encodable & Sendable>(_ value: T) throws -> Data
}

/// JSON implementation of `RequestEncoder`.
public struct JSONRequestEncoder: RequestEncoder, Sendable {
    public let encoder: JSONEncoder

    public init(
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601,
        keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
    ) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy
        encoder.keyEncodingStrategy = keyEncodingStrategy
        self.encoder = encoder
    }

    public init(encoder: JSONEncoder) {
        self.encoder = encoder
    }

    public func encode<T: Encodable & Sendable>(_ value: T) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw NetworkError.encoding(error.localizedDescription)
        }
    }
}
