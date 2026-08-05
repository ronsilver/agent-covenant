# CocoaPods / SPM Distribution

## Podspec
```ruby
Pod::Spec.new do |s|
  s.name         = "CheckoutSDK"
  s.version      = "1.2.0"
  s.summary      = "checkout SDK for iOS"
  s.homepage     = "https://github.com/example/mobile-sdk-ios"
  s.source       = { :git => "...", :tag => "ios/v1.2.0" }
  s.source_files = "Sources/**/*.swift"
  s.swift_version = "5.9"
  s.ios.deployment_target = "15.0"
end
```

## Package.swift (SPM)
```swift
let package = Package(
    name: "CheckoutSDK",
    platforms: [.iOS(.v15)],
    products: [.library(name: "CheckoutSDK", targets: ["CheckoutSDK"])],
    targets: [.target(name: "CheckoutSDK")]
)
```

## Version Bumping
- pod lib lint -> pod trunk push
- git tag ios/v{version}
- Update README with version badge
