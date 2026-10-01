import Foundation

/// Data passed to loggers representing a network lifecycle event.
public enum NetworkLogEvent: Sendable {
    case requestStarted(url: URL?, method: String, headers: [String: String], body: Data?)
    case responseReceived(url: URL?, statusCode: Int, headers: [String: String], body: Data?, duration: TimeInterval)
    case requestFailed(url: URL?, error: String)
}

/// Protocol for custom network logging.
public protocol NetworkLogger: Sendable {
    func log(_ event: NetworkLogEvent)
}

/// Default safe network logger that redacts sensitive headers and JSON body parameters.
public struct SafeConsoleLogger: NetworkLogger, Sendable {
    private static let sensitiveHeaders: Set<String> = [
        "authorization", "proxy-authorization", "cookie", "set-cookie",
        "x-api-key", "x-session-token", "x-auth-token"
    ]

    private static let sensitiveKeys: Set<String> = [
        "password", "pin", "cvv", "ssn", "access_token", "refresh_token",
        "otp", "card_number", "account_number", "secret"
    ]

    public init() {}

    public func log(_ event: NetworkLogEvent) {
        switch event {
        case .requestStarted(let url, let method, let headers, let body):
            let redactedHeaders = redactHeaders(headers)
            let redactedBodyString = redactBody(body)
            print("[Network Request] \(method) \(url?.absoluteString ?? "nil")")
            print("  Headers: \(redactedHeaders)")
            if let redactedBodyString {
                print("  Body: \(redactedBodyString)")
            }

        case .responseReceived(let url, let statusCode, let headers, let body, let duration):
            let redactedHeaders = redactHeaders(headers)
            let redactedBodyString = redactBody(body)
            print("[Network Response \(statusCode)] \(url?.absoluteString ?? "nil") (\(String(format: "%.3f", duration))s)")
            print("  Headers: \(redactedHeaders)")
            if let redactedBodyString {
                print("  Body: \(redactedBodyString)")
            }

        case .requestFailed(let url, let error):
            print("[Network Error] \(url?.absoluteString ?? "nil"): \(error)")
        }
    }

    /// Redacts sensitive HTTP header values.
    public func redactHeaders(_ headers: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in headers {
            if Self.sensitiveHeaders.contains(key.lowercased()) {
                result[key] = "[REDACTED]"
            } else {
                result[key] = value
            }
        }
        return result
    }

    /// Redacts sensitive keys in JSON payloads.
    public func redactBody(_ data: Data?) -> String? {
        guard let data = data, !data.isEmpty else { return nil }

        guard var jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return String(data: data, encoding: .utf8) ?? "<binary data>"
        }

        jsonObject = redactJSONObject(jsonObject)

        if let redactedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let string = String(data: redactedData, encoding: .utf8) {
            return string
        }

        return String(data: data, encoding: .utf8)
    }

    private func redactJSONObject(_ object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var newDict: [String: Any] = [:]
            for (key, value) in dict {
                if Self.sensitiveKeys.contains(key.lowercased()) {
                    newDict[key] = "[REDACTED]"
                } else {
                    newDict[key] = redactJSONObject(value)
                }
            }
            return newDict
        } else if let array = object as? [Any] {
            return array.map { redactJSONObject($0) }
        }
        return object
    }
}
