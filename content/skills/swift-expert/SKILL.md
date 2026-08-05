---
name: swift-expert
description: "Native iOS development with Swift: client SDK build and distribution (mobile-sdk), UIKit/SwiftUI, Objective-C bridges, packaging with CocoaPods/SPM, and CI/CD automation with Fastlane and Xcode CLI. Use when working on mobile-sdk, implementing native bridge modules, packaging SDK releases (CocoaPods, SPM), managing breaking-change versioning, configuring code signing, automating iOS builds in CI, or running XCTest suites. Trigger: Swift, iOS, Xcode, Fastlane, CocoaPods, SPM, SwiftUI, XCTest. Do NOT trigger for: Android development, Kotlin, backend Go services, React Native cross-platform logic."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: frontend
  status: stable
---
# Swift Expert

**iOS ecosystem: Swift, client SDK, CI/CD with Fastlane.**

## Core Stack

- Language: Swift 5.9+ (async/await, actors, macros, result builders)
- UI: SwiftUI + UIKit (interop when needed)
- Bridge: Objective-C compatibility (`@objc`, `@objcMembers`)
- SDK Dist: CocoaPods + Swift Package Manager
- Testing: XCTest (unit + UI tests)
- CI/CD: Fastlane (build, test, publish)
- Linting: SwiftLint
- Security: Keychain, App Transport Security (ATS)

## iOS SDK

| Repo | Distribution | Purpose |
|---|---|---|
| `mobile-sdk` | CocoaPods + SPM | Native client SDK |
| `example-ios-client` | Internal | Demo/test client app |

## Project Structure

```
Sources/ExampleFeature/
  Core/               # public API + client logic
  UI/                 # SwiftUI/UIKit components
  Networking/         # API client, request/response models
  Bridge/             # Obj-C compatibility layer
Tests/
  ExampleFeatureTests/
```

## Versioning (SemVer)

- MAJOR: breaking API change — migration guide mandatory
- MINOR: new feature, backward-compatible
- PATCH: bug fix, no API change
- NEVER release without updating CHANGELOG.md
- ALWAYS provide Obj-C compatibility shims (`@objc`, `@objcMembers`)

## Fastlane CI/CD

```ruby
# fastlane/Fastfile
default_platform(:ios)

lane :test do
  run_tests(
    scheme: "ExampleFeature",
    devices: ["iPhone 15 Pro"],
    xcargs: "-parallelizeTargets",
    output_directory: "test_output",
    output_types: "html,junit"
  )
end

lane :release do
  version = ENV["VERSION"] or UI.user_error!("VERSION required")
  set_podspec_version(version: version)
  test
  build_ios_app(scheme: "ExampleFeature", configuration: "Release")
  pod_push(path: "ExampleFeature.podspec", allow_warnings: true)
  git_tag(tag: "ios/v#{version}")
  push_git_tags
end
```

### GitHub Actions (iOS)

```yaml
name: iOS SDK CI
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/feature@v4
      - uses: actions/setup-ruby@v1
        with: { ruby-version: "3.2", bundler-cache: true }
      - uses: actions/cache@v4
        with: { path: Pods, key: pods-${{ hashFiles('Podfile.lock') }} }
      - run: bundle exec pod install
      - run: bundle exec fastlane test
      - uses: actions/upload-artifact@v4
        with: { name: test-results, path: test_output/ }
```

## Code Signing

- Use Fastlane Match for certificate/provisioning profile management
- NEVER store signing certificates in Git — GitHub Actions secrets or Match repo
- Separate signing identities per environment (dev/staging/production)

## Constraints

- NEVER break public API in MINOR/PATCH release
- NEVER ship with hardcoded API keys or endpoints
- ALWAYS provide Obj-C compatibility shims
- ALWAYS test backward compatibility with oldest supported iOS version
- NEVER store signing certificates in Git
- NEVER skip tests before publishing — test lane must pass first
- NEVER publish from local machine — CI only
- ALWAYS tag with platform prefix: `ios/v1.2.3`
- ALWAYS handle ARC retain cycles (weak self in closures)

## Overview

Swift with SwiftUI for native iOS client SDK development. This skill covers SDK packaging via CocoaPods/SPM, async/await networking, Obj-C bridge compatibility, Fastlane CI/CD, and code signing with Fastlane Match.

## Quick Reference

| Component | Technology | Purpose |
|---|---|---|
| UI | SwiftUI + UIKit interop | Native client screens |
| Async | Swift async/await + actors | Non-blocking operations |
| SDK Dist | CocoaPods + Swift Package Manager | Library distribution |
| CI/CD | Fastlane + GitHub Actions (macOS) | Build, test, sign, publish |
| Bridge | @objc compatibility | React Native integration |

## Workflow

1. Define public API surface with `public` access control and Obj-C shims
2. Implement SwiftUI views and ViewModels using `@Published` / `@Observable`
3. Wire async network calls with `async throws` and `URLSession.shared.data(for:)`
4. Write XCTest unit tests and UI tests for client flows
5. Run `swiftlint` and ensure all violations are fixed
6. Configure Fastlane `test` lane running on CI with `macos-14` runner
7. Use Fastlane Match for signing certificate management (never store in Git)
8. Tag release with platform prefix: `ios/v1.2.3` via CI only

## Anti-patterns

FAIL: ARC retain cycles from strong self references in closures
PASS: Always use `[weak self]` and guard-let pattern

```swift
// FAIL:
apiClient.fetchFeatureData { data in
    self.updateUI(data)  // strong reference → retain cycle
}

// PASS:
apiClient.fetchFeatureData { [weak self] data in
    guard let self else { return }
    self.updateUI(data)
}
```

FAIL: Breaking public API in MINOR/PATCH release
PASS: MAJOR bumps require migration guide and Obj-C shims

```swift
// FAIL: removed in v1.2.0 (MINOR)
public func startFeature(value: Decimal) { ... }
// Now: public func startFeature(value: Decimal, metadata: [String: String] = [:])

// PASS: deprecate + overload
@available(*, deprecated, message: "Use startFeature(value:metadata:)")
public func startFeature(value: Decimal) { ... }
public func startFeature(value: Decimal, metadata: [String: String] = [:]) { ... }
```

FAIL: Publishing SDK from local machine
PASS: CI-only publishing keeps signing certificates secure

```text
FAIL: bundle exec fastlane release VERSION=1.2.3  # from laptop — certificates exposed
PASS: GitHub Actions with MATCH_PASSWORD and MATCH_GIT_URL secrets
```

## References

- [Swift Concurrency (async/await)](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) (last_verified: 2025-01)
- [Swift Package Manager Documentation](https://www.swift.org/documentation/package-manager/) (last_verified: 2024-12)
- [Fastlane iOS Actions](https://docs.fastlane.tools/actions/) (last_verified: 2025-02)

- [references/cocoapods.md](references/cocoapods.md)
- [references/fastlane-patterns.md](references/fastlane-patterns.md)

## Verification Checklist

- [ ] Obj-C compatibility shims provided for all public API surface (`@objc`, `@objcMembers`)
- [ ] ARC retain cycles checked: `[weak self]` used in all closures
- [ ] Public API not broken in MINOR/PATCH release (deprecation overloads for changes)
- [ ] Fastlane `test` lane passes before any release
- [ ] Release done via CI only (not local machine)
- [ ] Git tag includes platform prefix: `ios/v1.2.3`
- [ ] No hardcoded API keys or endpoints in shipped code

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| ViewController/View not deallocated | Retain cycle — strong reference in closure | Add `[weak self]` to closures; check delegate properties are `weak` |
| CocoaPods build fails after SDK update | Podspec version not bumped | Update `version` in `.podspec` and run `pod lib lint` before release |
| Fastlane Match fails to install certificates | MATCH_PASSWORD env var missing or wrong | Verify `MATCH_PASSWORD` set in CI secrets; check Match repo access for CI user |
| Swift Package Manager resolves wrong dependency version (known issue: SPM dependency graph conflict) | Two dependencies pin incompatible versions of the same transitive dep | Use `--strict` version constraints; run `swift package resolve` locally to debug conflict; consider pinfile |

| [WARN] CocoaPods `pod install` downgrades dependency due to transitive constraint conflict | Two pods depend on different versions of same transitive dep; CocoaPods resolves to lowest common | Use `:git` or `:path` to pin transitive dependency; add explicit pod version in Podfile to override |
