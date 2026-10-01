import Foundation

/// Interface for retrieving authentication access tokens.
/// The host application provides the implementation (e.g., retrieving from Keychain).
public protocol AccessTokenProvider: Sendable {
    /// Fetches the current valid access token.
    func accessToken() async throws -> String?
}
