import Foundation

/// Configurable retry policy for transient network failures.
public struct RetryPolicy: Sendable {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maximumDelay: TimeInterval
    public let retryableStatusCodes: Set<Int>

    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 0.1,
        maximumDelay: TimeInterval = 5.0,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maximumDelay = maximumDelay
        self.retryableStatusCodes = retryableStatusCodes
    }

    /// Evaluates backoff delay for an attempt with exponential growth + random jitter.
    public func delay(forAttempt attempt: Int, retryAfterHeader: TimeInterval? = nil) -> TimeInterval {
        if let retryAfterHeader, retryAfterHeader > 0 {
            return min(retryAfterHeader, maximumDelay)
        }
        let exponentialFactor = pow(2.0, Double(attempt - 1))
        let calculatedDelay = baseDelay * exponentialFactor
        let jitter = Double.random(in: 0...(baseDelay * 0.5))
        return min(calculatedDelay + jitter, maximumDelay)
    }

    /// Determines whether an HTTP status code is retryable under this policy.
    public func isRetryable(statusCode: Int) -> Bool {
        retryableStatusCodes.contains(statusCode)
    }
}

/// Evaluates whether a request should be retried based on method, headers, and status code.
public struct RetryInterceptor: Sendable {
    public let policy: RetryPolicy

    public init(policy: RetryPolicy = RetryPolicy()) {
        self.policy = policy
    }

    /// Checks if a request and status code combination is eligible for retry.
    /// Retries transient failures only. Non-idempotent operations (POST, PATCH) are ONLY retried if an `Idempotency-Key` header is present.
    public func shouldRetry<Request: NetworkRequest>(
        request: Request,
        statusCode: Int,
        attempt: Int
    ) -> Bool {
        guard attempt <= policy.maxRetries else { return false }
        guard policy.isRetryable(statusCode: statusCode) else { return false }

        if request.method.isIdempotent {
            return true
        }

        // For non-idempotent methods, require Idempotency-Key header to safely retry
        let hasIdempotencyKey = request.headers["Idempotency-Key"] != nil
        return hasIdempotencyKey
    }
}
