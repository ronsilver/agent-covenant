# Release Automation

## semantic-release
```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/github"
  ]
}
```
Analyzes conventional commits, determines version bump, generates changelog.

## release-please (Google)
```yaml
- uses: googleapis/release-please-action@v4
  with:
    release-type: go
    package-name: api
```
Creates release PR, updates version files, publishes GitHub Release.

## GoReleaser
```yaml
- uses: goreleaser/goreleaser-action@v6
  with:
    args: release --clean
```
Cross-compiles binaries, builds Docker images, creates GitHub Release.

## Release Checklist
- [ ] CHANGELOG updated
- [ ] Version bumped
- [ ] Git tag created
- [ ] GitHub Release published
- [ ] Release artifacts attached
- [ ] Deployment triggered
