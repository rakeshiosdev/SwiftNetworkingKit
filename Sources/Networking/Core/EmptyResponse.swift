import Foundation

/// Represents an empty response body (e.g. HTTP 204 No Content).
public struct EmptyResponse: Decodable, Sendable, Equatable {
    public init() {}
}
