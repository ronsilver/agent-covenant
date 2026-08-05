---
name: kotlin-expert
description: "Native Android development with Kotlin: client SDK build and distribution (mobile-sdk), Jetpack Compose/Views, coroutines/Flow, packaging with Gradle/Maven, and CI/CD automation with Fastlane and Android Build Tools. Use when building Android SDKs, implementing Jetpack Compose UIs, packaging AAR libraries, or automating Android CI/CD. Trigger: mobile-sdk, Jetpack Compose, coroutines Flow, Gradle KTS, AAR packaging, Fastlane Android, ProGuard R8. Do NOT trigger for: iOS Swift SDK development, general Kotlin backend services, React Native JS logic."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: frontend
  status: stable
---
# Kotlin Expert

**Android ecosystem: Kotlin, client SDK, CI/CD with Fastlane.**

## Core Stack

- Language: Kotlin (coroutines, Flow, sealed classes, extension functions)
- UI: Jetpack Compose + legacy Views interop
- Async: coroutines (`suspend`, `runBlocking` only in tests)
- Build: Gradle KTS (`.gradle.kts`)
- SDK Dist: Maven Central / JitPack (AAR packaging)
- Testing: JUnit 5 + Espresso (instrumented) + MockK
- CI/CD: Fastlane (build, test, publish)
- Linting: ktlint + detekt
- Security: EncryptedSharedPreferences, network security config

## Android SDK

| Repo | Distribution | Purpose |
|---|---|---|
| `mobile-sdk` | Maven (AAR) | Native client SDK |
| `example-rn-bridge` | npm | React Native bridge (consumes native AAR) |

## Project Structure

```
sdk/src/main/java/com/example/sdk/
  feature/           # feature flow logic
  ui/                 # Compose/View components
  network/            # API client, models
  bridge/             # React Native bridge module
sdk/src/test/         # unit tests
sdk/src/androidTest/  # instrumented tests
```

## Versioning (SemVer)

- MAJOR: breaking API change — migration guide mandatory
- MINOR: new feature, backward-compatible
- PATCH: bug fix, no API change
- NEVER release without updating CHANGELOG.md
- ALWAYS minify/obfuscate AAR in release builds (ProGuard/R8)

## Fastlane CI/CD

```ruby
# fastlane/Fastfile
platform :android do
  lane :test do
    gradle(task: "test")
    gradle(task: "connectedAndroidTest",
           flags: "-PandroidTestInstrArguments='class com.example.sdk.FeatureTest'")
  end

  lane :release do
    version = ENV["VERSION"] or UI.user_error!("VERSION required")
    android_set_version_name(version_name: version)
    test
    gradle(task: "publish", build_type: "Release",
           properties: {
             "signing.keyId" => ENV["SIGNING_KEY_ID"],
             "signing.password" => ENV["SIGNING_KEY_PASSWORD"]
           })
    git_tag(tag: "android/v#{version}")
    push_git_tags
  end
end
```

### GitHub Actions (Android)

```yaml
name: Android SDK CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        api-level: [29, 34]
    steps:
      - uses: actions/feature@v4
      - uses: actions/setup-java@v4
        with: { java-version: "17", distribution: "temurin" }
      - uses: gradle/actions/setup-gradle@v3
      - run: ./gradlew test
      - name: Instrumented tests
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: ${{ matrix.api-level }}
          script: ./gradlew connectedCheck
```

## Coroutines & Flow

```kotlin
class FeatureViewModel(
    private val dataRepo: DataRepository
) : ViewModel() {
    private val _state = MutableStateFlow(FeatureState())
    val state: StateFlow<FeatureState> = _state.asStateFlow()

    fun submitData(item: FeatureData) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            try {
                val result = dataRepo.createData(item)
                _state.update { it.copy(isLoading = false, status = result.status) }
            } catch (e: Exception) {
                _state.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }
}
```

## React Native Bridge

```kotlin
class ExampleModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "ExampleModule"

    @ReactMethod
    fun startFeature(config: ReadableMap, promise: Promise) {
        // Launch native feature activity
    }
}
```

## Constraints

- NEVER break public API in MINOR/PATCH release
- NEVER ship with hardcoded API keys or endpoints
- NEVER block main thread — coroutines for async work
- ALWAYS minify/obfuscate AAR in release builds (ProGuard/R8)
- NEVER include test utilities in production SDK artifact
- NEVER skip tests before publishing
- NEVER publish from local machine — CI only
- ALWAYS tag with platform prefix: `android/v1.2.3`
- NEVER store signing keys in Git — use GitHub Actions secrets
- NEVER run instrumented tests without emulator setup step

## Overview

Kotlin with Jetpack Compose for native Android client SDK development. This skill covers SDK packaging as AAR, React Native bridge modules, coroutine-based async patterns, Fastlane CI/CD, and ProGuard minification.

## Quick Reference

| Component | Technology | Purpose |
|---|---|---|
| UI | Jetpack Compose + Views interop | Native feature screens |
| Async | Coroutines + StateFlow | Non-blocking operations, reactive state |
| SDK Dist | Maven Central / JitPack (AAR) | Library distribution |
| CI/CD | Fastlane + GitHub Actions | Build, test, sign, publish |
| Bridge | React Native module | Cross-platform feature integration |

## Workflow

1. Define data models and API client in the `network/` package
2. Implement Compose UI components with `StateFlow` for reactive state management
3. Wire ViewModel with coroutines: `viewModelScope.launch` for async operations
4. Write unit tests (JUnit 5 + MockK) and instrumented tests (Espresso)
5. Run `./gradlew test` locally, `ktlint check`, and `detekt`
6. Configure Fastlane lanes for test, build, and release with signing
7. Tag release with platform prefix: `android/v1.2.3` via CI only
8. Distribute AAR to Maven/JitPack for consumer apps

## Anti-patterns

FAIL: Breaking public API in a MINOR/PATCH release
PASS: MAJOR bumps require migration guide

```kotlin
// FAIL: changed in v1.2.0 (MINOR)
// Old: fun processData(item: FeatureData): DataStatus
// New: fun processData(item: FeatureData, metadata: Map<String, String>): DataStatus
// ^ breaks binary compatibility

// PASS:
fun processData(item: FeatureData): DataStatus   // keep old
fun processData(item: FeatureData, metadata: Map<String, String>): DataStatus  // add overloaded
```

FAIL: Blocking main thread with synchronous network calls
PASS: Always use coroutines for async operations

```kotlin
// FAIL:
fun submitData(item: FeatureData) {
    val result = api.createData(item)  // blocks main thread → ANR
}

// PASS:
fun submitData(item: FeatureData) {
    viewModelScope.launch {
        val result = withContext(Dispatchers.IO) {
            api.createData(item)
        }
    }
}
```

FAIL: Publishing SDK artifact from local machine
PASS: CI-only publishing ensures signing keys are never in developer environments

```text
FAIL: ./gradlew publishToMavenCentral  # from laptop — keys exposed in local gradle.properties
PASS: GitHub Actions with secrets.SIGNING_KEY_ID, secrets.SIGNING_KEY_PASSWORD
```

## References

- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html) (last_verified: 2026-05-25)
- [Jetpack Compose Documentation](https://developer.android.com/develop/ui/compose/documentation) (last_verified: 2026-05-25)
- [Fastlane Android Actions](https://docs.fastlane.tools/actions/android/) (last_verified: 2026-05-25)

- [references/compose-patterns.md](references/compose-patterns.md)
- [references/testing.md](references/testing.md)

## Verification Checklist

- [ ] ProGuard/R8 minification enabled for release AAR builds
- [ ] No hardcoded API keys or endpoints in production SDK artifact
- [ ] Coroutines used for async work (main thread never blocked)
- [ ] SDK published via CI only (never from local machine)
- [ ] Release tagged with platform prefix: `android/v<major>.<minor>.<patch>`
- [ ] Breaking API changes gated behind MAJOR version bump with migration guide
- [ ] Instrumented tests pass on target API levels via emulator CI matrix

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| AAR import fails with duplicate class error | React Native bridge module conflicts with host app | Use `consumerProguardFiles` to deduplicate; scope classes with package names |
| Fastlane publish fails with signing error | Signing key env vars not set in CI secrets | Add `SIGNING_KEY_ID`, `SIGNING_KEY_PASSWORD` to GitHub Actions secrets |
| `Method not found` on device | ProGuard obfuscation removed method accessed via reflection | Add `-keep` rule in ProGuard config for reflection-accessed classes |
| Known issue: `@ReactMethod` callback not invoked on JS thread | Native module uses wrong thread for promise resolution | Ensure promise.resolve/reject called on the React Native JS thread via `reactContext.runOnJSQueueThread` |

| [WARN] Kotlin coroutine cancels silently in `withContext(Dispatchers.IO)` | CancellationException swallowed by IO dispatcher; caller never knows task was cancelled | Wrap IO block with `ensureActive()` checks; use `withContext(NonCancellable)` only when truly needed |
