import Foundation

/// Standard HTTP methods for network requests.
public struct HTTPMethod: RawRepresentable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public static let get = HTTPMethod(rawValue: "GET")
    public static let post = HTTPMethod(rawValue: "POST")
    public static let put = HTTPMethod(rawValue: "PUT")
    public static let patch = HTTPMethod(rawValue: "PATCH")
    public static let delete = HTTPMethod(rawValue: "DELETE")
    public static let head = HTTPMethod(rawValue: "HEAD")
    public static let options = HTTPMethod(rawValue: "OPTIONS")

    /// Returns `true` if the HTTP method is considered idempotent by HTTP specification (GET, HEAD, PUT, DELETE, OPTIONS).
    public var isIdempotent: Bool {
        switch self {
        case .get, .head, .put, .delete, .options:
            return true
        default:
            return false
        }
    }

    public var description: String {
        rawValue
    }
}
