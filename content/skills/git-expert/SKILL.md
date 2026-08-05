---
name: git-expert
description: "Mastery of Git protocol: internal objects (blob, tree, commit, tag), content-addressable filesystem, safe history rewriting (interactive rebase, filter-repo), reflog for recovery, local and server-side hooks, guardrails against force-pushes, secret leak detection, signed commits (GPG/SSH), conventional commits, and branching strategies (trunk-based, GitHub Flow). Use when writing conventional commit messages, creating feature branches, handling merge conflicts, setting up git hooks, configuring commit signing, or enforcing push policies. Trigger: Git protocol, git merge, git rebase, git cherry-pick, git stash, git branch, git checkout, git diff, git log, conventional commits, signed commits. Do NOT trigger for: GitHub UI navigation or repository administration without Git command usage."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---
# Git Expert

**Git protocol: commits, branching, hooks, security and recovery.**

## Core Stack

- Protocol: Smart HTTP, SSH, Git protocol
- Internals: Objects (blob, tree, commit, tag), packfiles, reflog
- Branching: Trunk-Based Development (default for cloud-native projects), GitHub Flow
- Safety: --force-with-lease, signed commits (GPG/SSH), git-secrets/gitleaks
- Conventions: Conventional Commits (default for cloud-native projects)

## Conventional Commits

```
type(scope): description

[optional body]

[optional footer(s)]
```

| Type | Use |
|---|---|
| `feat` | New feature (MINOR semver) |
| `fix` | Bug fix (PATCH semver) |
| `refactor` | Code restructure, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding/updating tests |
| `docs` | Documentation only |
| `chore` | Maintenance, deps, config |
| `ci` | CI/CD changes |
| `build` | Build system changes |
| `revert` | Revert previous commit |

```
feat(api): add idempotency key support to resource creation

Implements idempotency key validation with 24h deduplication window.
Uses Redis to store key -> response mapping with TTL.

Closes #1234
```

## Signed Commits

```bash
# GPG signing
git config --global commit.gpgsign true
git config --global user.signingkey <KEY_ID>

# SSH signing (GitHub)
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

## Branching Strategy

```bash
# Trunk-Based Development (recommended)
main                     # production-ready, always deployable
  feat/<slug>            # short-lived feature branch
  fix/<slug>             # short-lived bug fix
```

### Protected branches

The following branch names are protected and MUST NEVER be used as a new
feature/fix branch name, nor pushed to directly:

- `main`
- `master`
- `develop`
- `development`
- `staging`
- `sandbox`

Always create a prefixed branch (`feat/<slug>`, `fix/<slug>`, `refactor/<slug>`,
`docs/<slug>`, `test/<slug>`) instead. If the chosen name collides with a
protected branch, pick a different prefixed name before creating it.

## Safety Guardrails

```bash
# NEVER use --force on shared branches
git push --force-with-lease origin main           # safer force push

# Recover lost commits via reflog
git reflog
git checkout HEAD@{2}                              # go back 2 operations
git branch recovered-branch HEAD@{2}

# Undo last commit (keep changes)
git reset --soft HEAD~1
```

## Secrets Prevention

```bash
# Pre-commit hook to detect secrets
# .git/hooks/pre-commit
#!/bin/bash
if git-secrets --scan; then
    echo "No secrets found"
else
    echo "Secret detected! Commit blocked."
    exit 1
fi
```

## Conflict Resolution

```bash
git pull --rebase origin main
# Resolve conflicts in each file
git add <resolved-file>
git rebase --continue
git push --force-with-lease origin feat/my-branch
```

## Constraints

- NEVER force push to main/master (use --force-with-lease on feature branches only)
- NEVER push without signed commits configured in repos
- NEVER use git add -A / git add . without reviewing changes first
- NEVER commit secrets, .env files, or credentials (even in test fixtures)
- ALWAYS use conventional commit format for all repos
- ALWAYS pull --rebase before push to avoid merge bubbles
- NEVER commit directly to main (always via PR) in protected repos
- NEVER create a branch whose name equals a protected branch (main, master, develop, development, staging, sandbox)
- ALWAYS ask for explicit user confirmation before `git push` (push is an ask-gated operation)

## Overview

Master Git protocol: objects (blob, tree, commit, tag), safe history rewriting (interactive rebase, filter-repo), reflog for recovery, local and server-side hooks, signed commits (GPG/SSH), conventional commits, secret leak detection, and branching strategies (trunk-based, GitHub Flow).

## Quick Reference

| Operation | Command | Safety |
|---|---|---|
| Force push | git push --force-with-lease | Safer than --force (checks remote) |
| Undo last commit | git reset --soft HEAD~1 | Keeps changes staged |
| Recover loss | git reflog + git checkout | Works for 90 days by default |
| Signed commit | git commit -S | GPG or SSH signature |
| Secret scan | git-secrets --scan | Pre-commit hook prevents leaks |

## Workflow

1. Create short-lived feature branch: `feat/<slug>` or `fix/<slug>`
2. Make small commits with conventional commit format
3. Pull --rebase before push to avoid merge bubbles
4. Push with `--force-with-lease` if rebasing a feature branch
5. Open PR for code review (never commit directly to main)
6. Squash merge via PR to keep main history clean

## Anti-patterns

FAIL: Force pushing to shared branches without --force-with-lease
```bash
# BAD: overwrites remote changes without warning
git push --force origin main

# GOOD: fails if remote has new commits
git push --force-with-lease origin main
```

FAIL: Committing secrets and pushing before detection
```bash
# BAD: secret in commit
git add . && git commit -m "fix: update config"
# Oops — .env was included

# GOOD: pre-commit hook blocks secrets
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
git-secrets --scan || exit 1
EOF
```

FAIL: Using `git add -A` without reviewing changes
```bash
# BAD: blindly stage everything
git add -A

# GOOD: review before staging
git status
git add -p  # interactive patch staging
```

## References

- Conventional Commits: https://www.conventionalcommits.org/ (last_verified: 2026-05)
- Git documentation: https://git-scm.com/doc (last_verified: 2026-05)
- GitHub secret scanning: https://docs.github.com/en/code-security/secret-scanning (last_verified: 2026-05)

- [references/recovery.md](references/recovery.md)
- [references/workflows.md](references/workflows.md)

## Verification Checklist
- [ ] Conventional commit format used: `type(scope): description`
- [ ] Signed commits configured (GPG or SSH) for cloud-native repos
- [ ] `git push --force-with-lease` used instead of `--force` on shared branches
- [ ] Pre-commit hook installed for secret detection (`git-secrets` or `gitleaks`)
- [ ] No `.env`, credentials, or secrets staged before commit (reviewed with `git status` + `git diff`)
- [ ] `git pull --rebase` used before push to avoid merge bubbles
- [ ] Never committing directly to `main` — always via PR for protected repos

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| `git push --force-with-lease` rejected | Remote branch has commits you haven't pulled | Pull first: `git pull --rebase origin feat/my-branch`, resolve conflicts, push again |
| Secret detected after commit pushed | `.env`, `.pem`, or credentials included in commit; no pre-commit hook | Use `git filter-repo` to remove from history; rotate exposed secrets; add pre-commit hook |
| GPG signing fails with `unusable secret key` | GPG key expired or not on this machine | Generate new key: `gpg --full-generate-key`; add to GitHub: `gpg --armor --export <KEY_ID> \| pbcopy` |
| Merge conflict on rebase is confusing | Large PR with many commits touching same files | Use `git rebase --interactive` to squash related commits; resolve conflicts incrementally |
| `git filter-repo` rewrites author dates even when only content changes (known limitation) | filter-repo default behavior converts author and committer timestamps to current time | Use `--refetch` or force date preservation with custom callback; document original timestamps before running |
