import Foundation

/// Primary implementation of `HTTPClient` backed by `URLSession`.
public final class NetworkClient: HTTPClient, Sendable {
    public let configuration: NetworkConfiguration
    private let session: URLSession
    private let tokenProvider: (any AccessTokenProvider)?
    private let tokenRefreshCoordinator: TokenRefreshCoordinator?
    private let requestInterceptors: [any RequestInterceptor]
    private let logger: (any NetworkLogger)?
    private let decoder: any ResponseDecoder
    private let errorMapper: NetworkErrorMapper

    public init(
        configuration: NetworkConfiguration,
        session: URLSession? = nil,
        tokenProvider: (any AccessTokenProvider)? = nil,
        tokenRefreshCoordinator: TokenRefreshCoordinator? = nil,
        requestInterceptors: [any RequestInterceptor] = [],
        logger: (any NetworkLogger)? = SafeConsoleLogger(),
        decoder: any ResponseDecoder = JSONResponseDecoder()
    ) {
        self.configuration = configuration
        self.tokenProvider = tokenProvider
        self.tokenRefreshCoordinator = tokenRefreshCoordinator
        self.requestInterceptors = requestInterceptors
        self.logger = logger
        self.decoder = decoder
        self.errorMapper = NetworkErrorMapper()

        if let session {
            self.session = session
        } else {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
            sessionConfig.timeoutIntervalForResource = configuration.resourceTimeoutInterval
            
            // NOTE: Certificate Pinning is intentionally disabled and can be re-enabled later.
            // Uncomment the delegate line below to re-enable certificate pinning delegate handling.
            // let delegate = PinningURLSessionDelegate(configuration: configuration.certificatePinning)
            // self.session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)
            self.session = URLSession(configuration: sessionConfig)
        }
    }

    public func send<Request: NetworkRequest>(_ request: Request) async throws -> Request.Response {
        return try await executeWithRetry(request: request, attempt: 1)
    }

    private func executeWithRetry<Request: NetworkRequest>(
        request: Request,
        attempt: Int
    ) async throws -> Request.Response {
        var urlRequest = try buildURLRequest(from: request)

        // Apply request interceptors
        if let tokenProvider {
            let authInterceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
            try await authInterceptor.adapt(&urlRequest)
        }
        for interceptor in requestInterceptors {
            try await interceptor.adapt(&urlRequest)
        }

        let startTime = Date()
        logger?.log(.requestStarted(
            url: urlRequest.url,
            method: urlRequest.httpMethod ?? request.method.rawValue,
            headers: urlRequest.allHTTPHeaderFields ?? [:],
            body: urlRequest.httpBody
        ))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let urlError as URLError {
            let mapped = errorMapper.map(urlError: urlError)
            logger?.log(.requestFailed(url: urlRequest.url, error: mapped.localizedDescription))
            throw mapped
        } catch {
            if Task.isCancelled {
                throw NetworkError.cancelled
            }
            throw NetworkError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let duration = Date().timeIntervalSince(startTime)
        logger?.log(.responseReceived(
            url: httpResponse.url,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
            body: data,
            duration: duration
        ))

        let statusCode = httpResponse.statusCode

        // Check 401 Unauthorized -> Refresh Token Flow
        if statusCode == 401, attempt == 1, let coordinator = tokenRefreshCoordinator {
            do {
                _ = try await coordinator.refreshToken()
                // Retry request with fresh token once
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            } catch {
                throw NetworkError.unauthorized
            }
        }

        // Check retry policy for transient errors (408, 429, 500, 502, 503, 504)
        if let policy = configuration.retryPolicy {
            let interceptor = RetryInterceptor(policy: policy)
            if interceptor.shouldRetry(request: request, statusCode: statusCode, attempt: attempt) {
                let parseRetryAfter = parseRetryAfter(from: httpResponse)
                let backoffDelay = policy.delay(forAttempt: attempt, retryAfterHeader: parseRetryAfter)
                
                if backoffDelay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }
        }

        // Validate HTTP Status Code
        guard (200...299).contains(statusCode) else {
            throw errorMapper.map(statusCode: statusCode, data: data, response: httpResponse)
        }

        // Handle Empty Response
        if Request.Response.self == EmptyResponse.self {
            guard let empty = EmptyResponse() as? Request.Response else {
                throw NetworkError.decoding("Failed to construct EmptyResponse")
            }
            return empty
        }

        do {
            return try decoder.decode(Request.Response.self, from: data)
        } catch let netError as NetworkError {
            throw netError
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }

    private func buildURLRequest<Request: NetworkRequest>(from request: Request) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }

        let path = request.path
        let fullPath: String
        if path.hasPrefix("/") {
            fullPath = path
        } else {
            fullPath = "/" + path
        }

        if components.path.isEmpty || components.path == "/" {
            components.path = fullPath
        } else {
            let existingPath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
            components.path = existingPath + fullPath
        }

        if !request.queryItems.isEmpty {
            var existingItems = components.queryItems ?? []
            existingItems.append(contentsOf: request.queryItems)
            components.queryItems = existingItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method.rawValue

        // Merge default headers with request-specific headers
        let mergedHeaders = configuration.defaultHeaders.merging(request.headers)
        for (key, value) in mergedHeaders.rawDictionary {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = request.body

        return urlRequest
    }

    private func parseRetryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        if let headerValue = response.value(forHTTPHeaderField: "Retry-After"),
           let seconds = TimeInterval(headerValue) {
            return seconds
        }
        return nil
    }
}
