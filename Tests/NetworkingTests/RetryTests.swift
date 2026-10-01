import Foundation
import Testing
@testable import Networking

struct IdempotentTestRequest: NetworkRequest {
    typealias Response = [Account]

    let path = "/v1/test"
    let method: HTTPMethod = .get
}

struct NonIdempotentTestRequest: NetworkRequest {
    typealias Response = [Account]

    let path = "/v1/transfer"
    let method: HTTPMethod = .post
    let headers: HTTPHeaders

    init(idempotencyKey: String? = nil) {
        if let key = idempotencyKey {
            self.headers = ["Idempotency-Key": key]
        } else {
            self.headers = [:]
        }
    }
}

private final class AtomicCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func incrementAndGet() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}

@Suite struct RetryTests {

    @Test func testRetry500Then500Then200Succeeds() async throws {
        let testID = "testRetry500Then500Then200Succeeds"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let retryPolicy = RetryPolicy(maxRetries: 3, baseDelay: 0.01, maximumDelay: 0.05)
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID], retryPolicy: retryPolicy)
        let client = NetworkClient(configuration: config, session: session)

        let mockAccounts = [Account(id: "acc_1", balance: 100, currency: "USD")]
        let mockData = try JSONEncoder().encode(mockAccounts)

        let counter = AtomicCounter()

        MockURLProtocol.setHandler(for: testID) { req in
            let currentAttempt = counter.incrementAndGet()

            if currentAttempt < 3 {
                let response = HTTPURLResponse(
                    url: req.url!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data())
            } else {
                let response = HTTPURLResponse(
                    url: req.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (response, mockData)
            }
        }

        let result = try await client.send(IdempotentTestRequest())
        #expect(result == mockAccounts)
        #expect(MockURLProtocol.count(for: testID) == 3)
    }

    @Test func testRetryExhaustionFails() async throws {
        let testID = "testRetryExhaustionFails"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let retryPolicy = RetryPolicy(maxRetries: 2, baseDelay: 0.01, maximumDelay: 0.05)
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID], retryPolicy: retryPolicy)
        let client = NetworkClient(configuration: config, session: session)

        MockURLProtocol.setHandler(for: testID) { req in
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await client.send(IdempotentTestRequest())
            Issue.record("Expected serverError")
        } catch NetworkError.serverError(let code) {
            #expect(code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(MockURLProtocol.count(for: testID) == 3) // Initial + 2 retries
    }

    @Test func testNonIdempotentPostWithoutIdempotencyKeyDoesNotRetry() async throws {
        let testID = "testNonIdempotentPostWithoutIdempotencyKeyDoesNotRetry"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let retryPolicy = RetryPolicy(maxRetries: 3, baseDelay: 0.01, maximumDelay: 0.05)
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID], retryPolicy: retryPolicy)
        let client = NetworkClient(configuration: config, session: session)

        MockURLProtocol.setHandler(for: testID) { req in
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let request = NonIdempotentTestRequest(idempotencyKey: nil)

        do {
            _ = try await client.send(request)
            Issue.record("Expected failure")
        } catch NetworkError.serverError(let code) {
            #expect(code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(MockURLProtocol.count(for: testID) == 1) // Should NOT retry non-idempotent POST without key
    }

    @Test func testNonIdempotentPostWithIdempotencyKeyDoesRetry() async throws {
        let testID = "testNonIdempotentPostWithIdempotencyKeyDoesRetry"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let retryPolicy = RetryPolicy(maxRetries: 2, baseDelay: 0.01, maximumDelay: 0.05)
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID], retryPolicy: retryPolicy)
        let client = NetworkClient(configuration: config, session: session)

        MockURLProtocol.setHandler(for: testID) { req in
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let request = NonIdempotentTestRequest(idempotencyKey: "tx_req_999")

        do {
            _ = try await client.send(request)
        } catch NetworkError.serverError(let code) {
            #expect(code == 500)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(MockURLProtocol.count(for: testID) == 3) // Initial + 2 retries
    }
}
