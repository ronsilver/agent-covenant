# Git Recovery

## Undo Last Commit (keep changes)
```bash
git reset --soft HEAD~1
```

## Recover Lost Commits
```bash
git reflog
git checkout HEAD@{2}  # go back 2 ops
git branch recovered HEAD@{2}
```

## Purge Secrets from History
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
# ROTATE all exposed credentials immediately
```

## Conflict Resolution
```bash
git pull --rebase origin main
# Fix conflicts in editor
git add resolved.txt
git rebase --continue
```
