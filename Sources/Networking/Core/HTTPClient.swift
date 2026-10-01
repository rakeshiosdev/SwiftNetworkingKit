import Foundation

/// Core protocol for sending network requests.
public protocol HTTPClient: Sendable {
    /// Sends a strongly typed network request and returns the decoded response.
    func send<Request: NetworkRequest>(
        _ request: Request
    ) async throws -> Request.Response
}
