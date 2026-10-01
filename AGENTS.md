# Networking SPM — Project Guidelines

## Purpose

This is a production-grade Swift Package Manager networking library for enterprise and banking iOS applications.

Keep the package:

* Modular
* Secure
* Testable
* Concurrency-safe
* Reusable
* Dependency-injected
* Free from application-specific business logic

---

## Architecture

* Use a modular architecture with clear separation of responsibilities.
* Keep networking concerns inside the `Networking` package.
* Use protocol-oriented design where appropriate.
* Use dependency injection.
* Prefer composition over inheritance.
* Keep the public API minimal.
* Do not create a global `NetworkManager.shared` singleton.
* Do not create a large `NetworkManager`/god object.
* Keep business logic outside the networking package.

Recommended areas:

* Core
* Authentication
* Interceptors
* Encoding
* Decoding
* Errors
* Security
* Utilities

---

## Swift

* Use Swift 6.
* Use Swift Concurrency and `async/await`.
* Follow strict concurrency safety.
* Use `Sendable` appropriately.
* Use actors for shared mutable state where appropriate.
* Prefer immutable state.
* Support structured concurrency and cancellation.
* Avoid unnecessary `@unchecked Sendable`.
* Avoid force unwraps (`!`).
* Avoid force casts (`as!`).
* Avoid global mutable state.

---

## Networking

* Use `URLSession` as the networking transport.
* Use strongly typed `NetworkRequest` abstractions.
* Decode responses using `Codable`.
* Use `JSONEncoder` and `JSONDecoder`.
* Support configurable base URLs.
* Do not hard-code environment URLs.
* Do not use third-party networking libraries unless explicitly requested.
* Do not expose `URLSession` directly to consuming application features.
* Keep request construction and response handling testable.

---

## Authentication

* Authentication must use dependency injection.
* Use an `AccessTokenProvider` abstraction.
* Do not store tokens inside the Networking package.
* Do not store passwords, OTPs, PINs, CVVs, or credentials.
* Token persistence belongs to the consuming application.
* Use Keychain through an injected abstraction when required.

### Token Refresh

* Token refresh must be concurrency-safe.
* Multiple simultaneous `401` responses must trigger only one refresh operation.
* Other requests must await the existing refresh operation.
* Retry the original request after successful refresh.
* Prevent infinite authentication retry loops.
* Propagate refresh failures correctly.

---

## Retry Policy

* Retry only transient failures.
* Support configurable retry counts.
* Use exponential backoff with jitter.
* Respect `Retry-After` for `429` where appropriate.

Potential retry status codes:

* `408`
* `429`
* `500`
* `502`
* `503`
* `504`

Do not automatically retry:

* `400`
* `403`
* `404`
* validation failures

Handle `401` through authentication refresh.

### Banking Transactions

Never blindly retry non-idempotent operations such as:

* Payments
* Transfers
* Withdrawals
* Deposits

Use idempotency keys where appropriate.

---

## Security

Treat all networking code as security-sensitive.

* Use HTTPS.
* Never disable TLS validation to fix development issues.
* Never hard-code credentials or API secrets.
* Never log access tokens or refresh tokens.
* Never log passwords, OTPs, PINs, CVVs, account numbers, or PII.
* Redact sensitive headers and values.
* Keep certificate pinning configurable.
* Do not hard-code certificates inside the HTTP client.
* Consider certificate rotation when implementing pinning.
* Do not put sensitive information in URLs unless unavoidable.

Example:

```text
Authorization: [REDACTED]
```

---

## Logging

* Use a logging abstraction.
* Do not use `print()` for production networking logs.
* Logging must be safe by default.
* Production logs must not contain sensitive customer or authentication data.
* Redact sensitive headers and payload fields.
* Make verbose logging configurable.

---

## Error Handling

* Use a typed `NetworkError`.
* Distinguish transport, HTTP, decoding, encoding, authentication, and cancellation errors.
* Preserve useful underlying errors where appropriate.
* Do not silently swallow errors.
* Do not swallow `CancellationError`.
* Keep error mapping deterministic.

---

## Testing

* Add tests for every important networking behavior.
* Use `URLProtocol` or an equivalent injectable mock transport.
* Test request construction.
* Test query parameters.
* Test headers.
* Test JSON encoding.
* Test JSON decoding.
* Test HTTP status handling.
* Test retry behavior.
* Test authentication refresh.
* Test concurrent token refresh.
* Test cancellation.
* Test logging redaction.

At minimum cover:

```text
200
201
204
400
401
403
404
408
429
500
502
503
504
```

For token refresh, verify:

```text
Multiple 401 responses
        ↓
Single refresh request
        ↓
All requests retry
```

---

## Public API

* Keep public APIs small and intentional.
* Do not make implementation details `public`.
* Prefer `internal` by default.
* Document public APIs.
* Avoid unnecessary public initializers.
* Preserve API compatibility unless a breaking change is explicitly requested.

Before making a type `public`, ask:

> Does the consuming application actually need access to this type?

---

## Package Structure

Do not recreate the existing SPM package.

Work inside the existing package.

Preferred structure:

```text
Networking/
├── AGENTS.md
├── Package.swift
├── Sources/
│   └── Networking/
│       ├── Core/
│       ├── Authentication/
│       ├── Interceptors/
│       ├── Encoding/
│       ├── Decoding/
│       ├── Errors/
│       ├── Security/
│       └── Utilities/
└── Tests/
    └── NetworkingTests/
```

Adapt the structure to the existing implementation instead of blindly replacing files.

---

## Code Quality

* Prefer small, focused types.
* Prefer small functions.
* Avoid god objects.
* Avoid unnecessary abstractions.
* Avoid duplicate functionality.
* Avoid premature optimization.
* Keep code readable and maintainable.
* Follow Swift naming conventions.
* Use explicit dependency injection.
* Do not introduce unrelated refactoring.

---

## Changes

Before modifying code:

1. Inspect the existing implementation.
2. Understand the current architecture.
3. Identify affected files.
4. Reuse existing abstractions where appropriate.
5. Make the smallest appropriate change.

Do not:

* Recreate the package.
* Delete working code unnecessarily.
* Modify unrelated files.
* Add unnecessary dependencies.
* Introduce breaking API changes without explicit approval.

---

## Before Finishing

Always:

1. Build the package.
2. Run all tests.
3. Fix compiler errors.
4. Fix failing tests.
5. Review Swift 6 concurrency warnings.
6. Review security implications.
7. Verify sensitive data is not logged.
8. Verify no unnecessary `@unchecked Sendable`.
9. Report changed files.
10. Report tests/build status.
11. Report remaining warnings or known limitations.

Use:

```bash
swift build
swift test
```

Do not report the task as complete if the build or tests are failing.

---

## Final Response

After completing a task, report briefly:

### Changed

* List modified files.
* List newly created files.
* Summarize important implementation changes.

### Validation

```text
Build: PASS/FAIL
Tests: PASS/FAIL
Concurrency warnings: <count>
Other warnings: <count>
```

### Notes

* Mention remaining limitations.
* Mention security considerations.
* Mention any follow-up work that is genuinely required.
