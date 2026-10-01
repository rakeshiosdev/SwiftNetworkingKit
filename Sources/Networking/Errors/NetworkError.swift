import Foundation

/// Strongly typed network errors thrown by `HTTPClient`.
public enum NetworkError: Error, Sendable, CustomStringConvertible {
    case invalidURL
    case invalidResponse
    case transport(URLError)
    case http(statusCode: Int, data: Data?)
    case decoding(String)
    case encoding(String)
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(statusCode: Int)
    case cancelled
    case unknown(String)

    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid HTTP Response"
        case .transport(let urlError):
            return "Transport error: \(urlError.localizedDescription)"
        case .http(let statusCode, _):
            return "HTTP error with status code \(statusCode)"
        case .decoding(let message):
            return "Decoding error: \(message)"
        case .encoding(let message):
            return "Encoding error: \(message)"
        case .unauthorized:
            return "Unauthorized (401)"
        case .forbidden:
            return "Forbidden (403)"
        case .notFound:
            return "Resource not found (404)"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Rate limited (429). Retry after \(retryAfter) seconds."
            }
            return "Rate limited (429)"
        case .serverError(let statusCode):
            return "Server error (\(statusCode))"
        case .cancelled:
            return "Request was cancelled"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.cancelled, .cancelled):
            return true
        case (.transport(let l), .transport(let r)):
            return l.code == r.code
        case (.http(let lCode, _), .http(let rCode, _)):
            return lCode == rCode
        case (.decoding(let l), .decoding(let r)):
            return l == r
        case (.encoding(let l), .encoding(let r)):
            return l == r
        case (.rateLimited(let l), .rateLimited(let r)):
            return l == r
        case (.serverError(let l), .serverError(let r)):
            return l == r
        case (.unknown(let l), .unknown(let r)):
            return l == r
        default:
            return false
        }
    }
}
