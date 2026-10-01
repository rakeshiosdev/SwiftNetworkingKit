import Foundation
import Testing
@testable import Networking

@Suite struct RequestTests {

    @Test func testHTTPHeadersCaseInsensitivity() {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        #expect(headers["content-type"] == "application/json")
        #expect(headers["CONTENT-TYPE"] == "application/json")

        headers["authorization"] = "Bearer token_123"
        #expect(headers["Authorization"] == "Bearer token_123")
    }

    @Test func testHeaderMerging() {
        let defaultHeaders: HTTPHeaders = [
            "User-Agent": "BankingApp/1.0",
            "Accept": "application/json"
        ]
        let requestHeaders: HTTPHeaders = [
            "Accept": "application/vnd.bank.v2+json",
            "Authorization": "Bearer abc"
        ]

        let merged = defaultHeaders.merging(requestHeaders)
        #expect(merged["User-Agent"] == "BankingApp/1.0")
        #expect(merged["Accept"] == "application/vnd.bank.v2+json")
        #expect(merged["Authorization"] == "Bearer abc")
    }

    @Test func testHTTPMethodIdempotency() {
        #expect(HTTPMethod.get.isIdempotent == true)
        #expect(HTTPMethod.put.isIdempotent == true)
        #expect(HTTPMethod.delete.isIdempotent == true)
        #expect(HTTPMethod.head.isIdempotent == true)
        #expect(HTTPMethod.post.isIdempotent == false)
        #expect(HTTPMethod.patch.isIdempotent == false)
    }
}
