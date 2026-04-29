---
description: Generate a CHANGELOG entry from commits since the last git tag
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(git tag *) Bash(git describe *)
---

Generate a CHANGELOG.md entry for the current version:

1. Find the last tag:
```bash
git describe --tags --abbrev=0 2>/dev/null || echo "none"
```

2. Get all commits since that tag (or all commits if no tags exist):
```bash
git log <last-tag>..HEAD --oneline   # or: git log --oneline if no tags
```

3. Group commits by conventional commit type:
   - **Features** — `feat:` commits
   - **Bug Fixes** — `fix:` commits
   - **Performance** — `perf:` commits
   - **Other** — `docs:`, `refactor:`, `chore:`, `style:` (omit trivial chores)

4. Format as a CHANGELOG.md entry using Keep a Changelog style:

```markdown
## [Unreleased] — YYYY-MM-DD

### Features
- Description of feature (commit short-sha)

### Bug Fixes
- Description of fix (commit short-sha)
```

5. Ask the user: "Append this to CHANGELOG.md, or just display it?"
   - If appending: insert below the `# Changelog` header, above any existing entries.
