Run the following bash command to find the sessions directory:

```bash
ls -t "$HOME/.claude/projects/-home-cclav-workspace/memory/sessions/" 2>/dev/null | head -5
```

If the directory doesn't exist yet, say "No previous session handoffs found" and ask what the user wants to work on.

Otherwise, read the file with the most recent timestamp in its filename.

After reading it, do the following:

1. Summarize what was accomplished in the previous session in 2-3 sentences.
2. State the current situation clearly.
3. List the next steps that were planned.
4. Ask the user: "Want me to pick up where we left off, or is there something else you want to tackle?"

Do not start working until the user responds. Just present the context and wait.
