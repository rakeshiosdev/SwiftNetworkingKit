import Foundation

/// Environmental configuration for the networking client.
public struct NetworkConfiguration: Sendable {
    public let baseURL: URL
    public let timeoutInterval: TimeInterval
    public let resourceTimeoutInterval: TimeInterval
    public let defaultHeaders: HTTPHeaders
    public let retryPolicy: RetryPolicy?
    public let certificatePinning: CertificatePinningConfiguration?

    public init(
        baseURL: URL,
        timeoutInterval: TimeInterval = 30.0,
        resourceTimeoutInterval: TimeInterval = 60.0,
        defaultHeaders: HTTPHeaders = [:],
        retryPolicy: RetryPolicy? = RetryPolicy(),
        certificatePinning: CertificatePinningConfiguration? = nil
    ) {
        self.baseURL = baseURL
        self.timeoutInterval = timeoutInterval
        self.resourceTimeoutInterval = resourceTimeoutInterval
        self.defaultHeaders = defaultHeaders
        self.retryPolicy = retryPolicy
        self.certificatePinning = certificatePinning
    }
}
