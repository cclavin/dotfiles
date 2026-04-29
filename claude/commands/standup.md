---
description: Generate a daily standup summary from recent git activity across workspace repos
disable-model-invocation: true
allowed-tools: Bash(find *) Bash(git log *) Bash(git config *)
---

Generate a standup summary from recent git activity:

1. Find all git repos in ~/workspace/code/:
```bash
find ~/workspace/code -maxdepth 2 -name .git -type d 2>/dev/null | sed 's|/.git||' | sort
```

2. Determine the lookback window: if today is Monday, use 3 days; otherwise use 1 day.

3. For each repo, get commits by the current user in that window:
```bash
git -C <repo> log --oneline --since="<N> days ago" --author="$(git config user.email)" 2>/dev/null
```

4. Format a standup summary:

```
**Yesterday** (or Since Friday)
- [project-name]: [what was accomplished]

**Today**
- [inferred next steps from recent commit direction and any open work]

**Blockers**
- None (or list if evident from context)
```

Keep it concise — standup style, not a detailed report. Group by project, skip repos with no activity.
