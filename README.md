# SwiftNetworkingKit

**Production-grade networking foundation for modern Swift & iOS applications.**

Designed with **Swift 6, structured concurrency, modular architecture, security, and testability** in mind for enterprise-scale applications.

## Highlights

* ⚡ Swift 6 + `async/await`
* 🧩 Protocol-oriented & dependency-injected architecture
* 🔐 Authentication & concurrent token refresh
* 🔄 Configurable retry & timeout policies
* 🛡️ Secure logging & sensitive-data redaction
* 🔒 Certificate Pinning architecture
* 📦 Typed requests & responses with `Codable`
* 🧪 `URLProtocol`-based network testing
* 🚫 No third-party networking dependencies

## Architecture

```text
SwiftNetworkingKit
├── Core
├── Authentication
├── Request / Response
├── Retry & Interceptors
├── Security
├── Logging
└── Testing
```

## Usage

```swift
import SwiftNetworkingKit

let response = try await client.send(request)
```

## Requirements

* iOS 16+
* Swift 6
* Swift Package Manager

## Design Goals

**Secure • Testable • Modular • Concurrent • Enterprise-ready**

> Built as a reusable networking foundation for large-scale iOS applications.
