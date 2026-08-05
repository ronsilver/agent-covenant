# Git Workflows

## Trunk-Based Dev (Generic default)
```bash
git checkout -b feat/batch-process
git commit -m "feat(api): add batch process support"
git pull --rebase origin main
git push -u origin feat/batch-process
# Create PR -> squash merge to main
```

## Conventional Commits
- feat: new feature (MINOR)
- fix: bug fix (PATCH)
- refactor: restructure
- chore: deps, config
- docs: documentation

## Safety Guardrails
- NEVER force push to main
- Use --force-with-lease on feature branches only
- ALWAYS pull --rebase before push
- ALWAYS signed commits (GPG/SSH)
