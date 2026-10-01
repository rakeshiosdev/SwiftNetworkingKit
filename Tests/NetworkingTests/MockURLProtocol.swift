import Foundation

public final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var _handlers: [String: @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]
    private nonisolated(unsafe) static var _defaultHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
    private nonisolated(unsafe) static var _history: [URLRequest] = []

    public static func setHandler(for testID: String, handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)) {
        lock.lock()
        defer { lock.unlock() }
        _handlers[testID] = handler
    }

    public static var defaultHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _defaultHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _defaultHandler = newValue
        }
    }

    public static func requests(for testID: String) -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return _history.filter { $0.value(forHTTPHeaderField: "X-Test-ID") == testID }
    }

    public static func count(for testID: String) -> Int {
        requests(for: testID).count
    }

    public static func reset() {
        lock.lock()
        defer { lock.unlock() }
        _handlers.removeAll()
        _defaultHandler = nil
        _history.removeAll()
    }

    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    public override func startLoading() {
        MockURLProtocol.lock.lock()
        MockURLProtocol._history.append(request)
        let testID = request.value(forHTTPHeaderField: "X-Test-ID")
        let handler = (testID != nil ? MockURLProtocol._handlers[testID!] : nil) ?? MockURLProtocol._defaultHandler
        MockURLProtocol.lock.unlock()

        guard let handler = handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    public override func stopLoading() {}
}

extension URLSession {
    public static func mockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
