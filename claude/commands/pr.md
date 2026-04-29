---
description: Create a GitHub pull request for the current branch
disable-model-invocation: true
allowed-tools: Bash(git log *) Bash(git diff *) Bash(git status) Bash(gh pr *)
---

Create a pull request for the current branch:

1. Run `git log main..HEAD --oneline` to see all commits included in this PR
2. Run `git diff main...HEAD --stat` to understand the full scope of changes
3. Draft a PR title (under 70 chars, imperative mood — e.g. "Add OAuth login flow")
4. Write a PR body in this format:

```
## Summary
- [bullet points: what changed and why, not how]

## Test plan
- [ ] [concrete steps to verify the change works]
```

5. Run `gh pr create --title "<title>" --body "<body>"`
6. Return the PR URL

Do not push to main directly. Do not create a draft unless the user asks.
