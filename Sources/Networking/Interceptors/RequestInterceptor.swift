import Foundation

/// Protocol for intercepting and adapting outgoing URLRequests.
public protocol RequestInterceptor: Sendable {
    func adapt(_ request: inout URLRequest) async throws
}
