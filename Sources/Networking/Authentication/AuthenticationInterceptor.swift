import Foundation

/// Request interceptor that attaches the Bearer token to requests.
public struct AuthenticationInterceptor: Sendable {
    private let tokenProvider: any AccessTokenProvider

    public init(tokenProvider: any AccessTokenProvider) {
        self.tokenProvider = tokenProvider
    }

    public func adapt(_ request: inout URLRequest) async throws {
        if let token = try await tokenProvider.accessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}
