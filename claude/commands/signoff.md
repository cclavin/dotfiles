Write a session handoff file to `/Users/Caleb/.claude/projects/-Users-Caleb-projects/memory/sessions/` using today's date and time as the filename in the format `YYYY-MM-DD-HH-MM.md`.

The file should be a complete, standalone context document structured as follows:

```
# Session Handoff — <date and time>

## Project / Working Directory
<project name and path>

## What Was Accomplished
<bullet list of completed tasks and changes made>

## Current State
<description of where things stand — what's working, what's in progress, any uncommitted changes>

## Key Files Changed
<list of files with brief description of what changed and why>

## Open Questions / Blockers
<anything unresolved, decisions pending, or blockers encountered>

## Next Steps
<concrete, ordered list of what to do next>

## Context to Know
<any background, decisions, constraints, or gotchas a future session needs to understand>
```

Be specific and thorough. A new Claude session reading this file cold should be able to pick up exactly where this session left off with no additional explanation.

After writing the file, confirm the path it was saved to.
