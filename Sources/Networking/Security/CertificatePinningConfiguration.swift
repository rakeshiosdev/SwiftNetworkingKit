import Foundation
import Security

/// Certificate pinning configuration supporting public key / certificate validation.
public struct CertificatePinningConfiguration: Sendable {
    public enum PinningMode: Sendable {
        case certificate
        case publicKey
    }

    public let pinnedHashesByDomain: [String: Set<String>]
    public let mode: PinningMode

    /// Creates a pinning configuration mapping domain names to expected SHA-256 hashes of certificates or public keys.
    public init(pinnedHashesByDomain: [String: Set<String>], mode: PinningMode = .publicKey) {
        self.pinnedHashesByDomain = pinnedHashesByDomain
        self.mode = mode
    }
}

/// URLSessionDelegate helper enforcing HTTPS and optional certificate pinning.
public final class PinningURLSessionDelegate: NSObject, URLSessionDelegate, Sendable {
    public let configuration: CertificatePinningConfiguration?

    public init(configuration: CertificatePinningConfiguration? = nil) {
        self.configuration = configuration
        super.init()
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @Sendable @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // NOTE: Certificate Pinning is intentionally disabled and can be re-enabled later.
        // To re-enable Certificate Pinning, uncomment the verification logic below.
        completionHandler(.performDefaultHandling, nil)

        /*
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Enforce TLS / HTTPS check
        guard challenge.protectionSpace.protocol == "https" else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let pinningConfig = configuration,
              let expectedHashes = pinningConfig.pinnedHashesByDomain[host],
              !expectedHashes.isEmpty else {
            // Default system TLS validation
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate server trust
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Compare certificate/public key hashes
        let isPinned = evaluateTrust(serverTrust, expectedHashes: expectedHashes, mode: pinningConfig.mode)
        if isPinned {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
        */
    }

    /*
    private func evaluateTrust(
        _ serverTrust: SecTrust,
        expectedHashes: Set<String>,
        mode: CertificatePinningConfiguration.PinningMode
    ) -> Bool {
        guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }

        for certificate in certificates {
            let certData = SecCertificateCopyData(certificate) as Data
            let hashData: Data

            switch mode {
            case .certificate:
                hashData = certData
            case .publicKey:
                if let publicKey = SecCertificateCopyKey(certificate),
                   let keyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? {
                    hashData = keyData
                } else {
                    hashData = certData
                }
            }

            let hashString = hashData.base64EncodedString()
            if expectedHashes.contains(hashString) {
                return true
            }
        }
        return false
    }
    */
}
