import Foundation

/// Defines standard HTTP status codes commonly used in network requests.
public enum HTTPStatusCode: Int, Sendable, CustomStringConvertible {
    // 2xx Success
    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    
    // 3xx Redirection
    case movedPermanently = 301
    case found = 302
    case notModified = 304
    
    // 4xx Client Errors
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case requestTimeout = 408
    case conflict = 409
    case unprocessableEntity = 422
    case tooManyRequests = 429
    
    // 5xx Server Errors
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    
    public var description: String {
        "HTTP Status \(rawValue)"
    }
    
    public var isSuccess: Bool {
        (200...299).contains(rawValue)
    }
    
    public var isClientError: Bool {
        (400...499).contains(rawValue)
    }
    
    public var isServerError: Bool {
        (500...599).contains(rawValue)
    }
}
