# Fastlane iOS Patterns

## Fastfile
```ruby
default_platform(:ios)

lane :test do
  run_tests(
    scheme: "CheckoutSDK",
    devices: ["iPhone 15 Pro"],
    xcargs: "-parallelizeTargets",
    output_directory: "test_output",
    output_types: "html,junit"
  )
end

lane :release do |options|
  version = options[:version] || ENV["VERSION"]
  increment_version_number(version_number: version)
  set_podspec_version(version: version, path: "CheckoutSDK.podspec")
  test
  build_ios_app(scheme: "CheckoutSDK", configuration: "Release")
  pod_push(path: "CheckoutSDK.podspec", allow_warnings: true)
  git_tag(tag: "ios/v#{version}")
  push_git_tags
end
```

## Code Signing
```ruby
# Use Match for certificate management
lane :setup_signing do
  match(type: "appstore", readonly: false)
end
```
NEVER store certificates in Git. Use Match repo or GitHub secrets.
