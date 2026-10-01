import Foundation
import Testing
@testable import SwiftNetworkingKit

final actor MockTokenProvider: AccessTokenProvider {
    private var token: String?

    init(token: String?) {
        self.token = token
    }

    func setToken(_ newToken: String?) {
        self.token = newToken
    }

    func accessToken() async throws -> String? {
        return token
    }
}

@Suite struct AuthenticationTests {

    @Test func testTokenRefreshOn401AndRetry() async throws {
        let testID = "testTokenRefreshOn401AndRetry"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let tokenProvider = MockTokenProvider(token: "expired_token")

        let refreshCoordinator = TokenRefreshCoordinator {
            // Simulate token refresh call
            let newToken = "fresh_token_123"
            await tokenProvider.setToken(newToken)
            return newToken
        }

        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID], retryPolicy: nil)
        let client = NetworkClient(
            configuration: config,
            session: session,
            tokenProvider: tokenProvider,
            tokenRefreshCoordinator: refreshCoordinator
        )

        let mockAccounts = [Account(id: "acc_1", balance: 100, currency: "USD")]
        let mockData = try JSONEncoder().encode(mockAccounts)

        MockURLProtocol.setHandler(for: testID) { req in
            let authHeader = req.value(forHTTPHeaderField: "Authorization")
            if authHeader == "Bearer expired_token" {
                let response = HTTPURLResponse(
                    url: req.url!,
                    statusCode: 401,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            } else if authHeader == "Bearer fresh_token_123" {
                let response = HTTPURLResponse(
                    url: req.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, mockData)
            } else {
                let response = HTTPURLResponse(
                    url: req.url!,
                    statusCode: 403,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            }
        }

        let result = try await client.send(GetAccountsRequest())
        #expect(result == mockAccounts)
        #expect(MockURLProtocol.count(for: testID) == 2)
    }
}
