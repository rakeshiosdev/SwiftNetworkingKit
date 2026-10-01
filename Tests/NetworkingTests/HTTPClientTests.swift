import Foundation
import Testing
@testable import Networking

struct Account: Codable, Sendable, Equatable {
    let id: String
    let balance: Decimal
    let currency: String
}

struct GetAccountsRequest: NetworkRequest {
    typealias Response = [Account]

    let path = "/v1/accounts"
    let method: HTTPMethod = .get
    let headers: HTTPHeaders = ["Accept": "application/json"]
    let queryItems: [URLQueryItem] = [URLQueryItem(name: "status", value: "active")]
    let body: Data? = nil
}

struct CreateAccountRequest: NetworkRequest {
    typealias Response = Account

    let path = "/v1/accounts"
    let method: HTTPMethod = .post
    let headers: HTTPHeaders = ["Content-Type": "application/json"]
    let queryItems: [URLQueryItem] = []
    let body: Data?

    init(account: Account) throws {
        self.body = try JSONEncoder().encode(account)
    }
}

struct DeleteAccountRequest: NetworkRequest {
    typealias Response = EmptyResponse

    let path: String
    let method: HTTPMethod = .delete
    var headers: HTTPHeaders { [:] }
    var queryItems: [URLQueryItem] { [] }
    var body: Data? { nil }

    init(id: String) {
        self.path = "/v1/accounts/\(id)"
    }
}

@Suite struct HTTPClientTests {

    @Test func testGetRequestSuccess() async throws {
        let testID = "testGetRequestSuccess"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID])
        let client = NetworkClient(configuration: config, session: session)

        let mockAccounts = [
            Account(id: "acc_1", balance: 1000.50, currency: "USD"),
            Account(id: "acc_2", balance: 2500.00, currency: "EUR")
        ]
        let responseData = try JSONEncoder().encode(mockAccounts)

        MockURLProtocol.setHandler(for: testID) { request in
            #expect(request.url?.absoluteString == "https://api.bank.com/v1/accounts?status=active")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }

        let accounts = try await client.send(GetAccountsRequest())
        #expect(accounts == mockAccounts)
        #expect(MockURLProtocol.count(for: testID) == 1)
    }

    @Test func testPostRequestSuccess() async throws {
        let testID = "testPostRequestSuccess"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID])
        let client = NetworkClient(configuration: config, session: session)

        let newAccount = Account(id: "acc_3", balance: 500.00, currency: "USD")
        let request = try CreateAccountRequest(account: newAccount)
        let responseData = try JSONEncoder().encode(newAccount)

        MockURLProtocol.setHandler(for: testID) { req in
            #expect(req.httpMethod == "POST")
            #expect(req.url?.path == "/v1/accounts")
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }

        let createdAccount = try await client.send(request)
        #expect(createdAccount == newAccount)
        #expect(MockURLProtocol.count(for: testID) == 1)
    }

    @Test func testDeleteRequestNoContent() async throws {
        let testID = "testDeleteRequestNoContent"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID])
        let client = NetworkClient(configuration: config, session: session)

        MockURLProtocol.setHandler(for: testID) { req in
            #expect(req.httpMethod == "DELETE")
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let result = try await client.send(DeleteAccountRequest(id: "acc_1"))
        #expect(result == EmptyResponse())
        #expect(MockURLProtocol.count(for: testID) == 1)
    }

    @Test func testMalformedJSONReturnsDecodingError() async throws {
        let testID = "testMalformedJSONReturnsDecodingError"
        let baseURL = try #require(URL(string: "https://api.bank.com"))
        let session = URLSession.mockSession()
        let config = NetworkConfiguration(baseURL: baseURL, defaultHeaders: ["X-Test-ID": testID])
        let client = NetworkClient(configuration: config, session: session)

        MockURLProtocol.setHandler(for: testID) { req in
            let response = HTTPURLResponse(
                url: req.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("invalid json".utf8))
        }

        await #expect(throws: NetworkError.self) {
            _ = try await client.send(GetAccountsRequest())
        }
    }
}
