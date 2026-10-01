import Foundation

/// Protocol representing a strongly typed network request.
public protocol NetworkRequest<Response>: Sendable {
    /// The decoded response type expected from the endpoint.
    associatedtype Response: Decodable & Sendable

    /// The API endpoint path relative to the base URL (e.g., "/v1/accounts").
    var path: String { get }

    /// The HTTP method for the request.
    var method: HTTPMethod { get }

    /// Additional HTTP headers specific to this request.
    var headers: HTTPHeaders { get }

    /// URL query parameters.
    var queryItems: [URLQueryItem] { get }

    /// The raw body data of the request, if any.
    var body: Data? { get }
}

public extension NetworkRequest {
    var headers: HTTPHeaders {
        [:]
    }

    var queryItems: [URLQueryItem] {
        []
    }

    var body: Data? {
        nil
    }
}
