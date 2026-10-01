import Foundation

/// Protocol for decoding HTTP response data into typed objects.
public protocol ResponseDecoder: Sendable {
    func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) throws -> T
}

/// JSON implementation of `ResponseDecoder`.
public struct JSONResponseDecoder: ResponseDecoder, Sendable {
    public let decoder: JSONDecoder

    public init(
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        self.decoder = decoder
    }

    public init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    public func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) throws -> T {
        if type == EmptyResponse.self {
            if let result = EmptyResponse() as? T {
                return result
            }
        }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }
}
