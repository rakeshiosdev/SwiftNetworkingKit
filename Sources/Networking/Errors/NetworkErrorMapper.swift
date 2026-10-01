import Foundation

/// Helper for mapping HTTP status codes and transport errors to `NetworkError`.
public struct NetworkErrorMapper: Sendable {
    public init() {}

    public func map(statusCode: Int, data: Data?, response: HTTPURLResponse? = nil) -> NetworkError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            let retryAfter = parseRetryAfter(from: response)
            return .rateLimited(retryAfter: retryAfter)
        case 500...599:
            return .serverError(statusCode: statusCode)
        default:
            return .http(statusCode: statusCode, data: data)
        }
    }

    public func map(urlError: URLError) -> NetworkError {
        if urlError.code == .cancelled {
            return .cancelled
        }
        return .transport(urlError)
    }

    private func parseRetryAfter(from response: HTTPURLResponse?) -> TimeInterval? {
        guard let response = response,
              let headerValue = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }
        if let seconds = TimeInterval(headerValue) {
            return seconds
        }
        return nil
    }
}
