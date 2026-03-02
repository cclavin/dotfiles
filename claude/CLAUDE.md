# Claude Code — Global Defaults

These instructions apply to every project. Project-level CLAUDE.md files extend or override these.

## Communication Style
- Be concise. Skip preamble, filler phrases, and closing summaries unless asked.
- No emojis unless explicitly requested.
- When referencing code, use `file_path:line_number` format.
- For multi-step tasks, use the task list to track progress.

## Workflow
- Always read a file before editing it.
- Prefer editing existing files over creating new ones.
- Avoid over-engineering — use the minimum complexity the task requires.
- Do not add comments, docstrings, or type annotations to code you did not change.
- Do not create documentation or README files unless explicitly asked.
- Do not propose changes to code you have not read.

## Safety
- Confirm before any destructive operation (file deletion, force push, hard reset, drop table).
- Never skip git hooks (`--no-verify`) unless explicitly instructed.
- Never commit unless explicitly asked.
- Never push unless explicitly asked.
- Never amend a published commit — create a new one instead.

## Code Style
- Prefer modern syntax (ES2022+, async/await, optional chaining, nullish coalescing).
- No trailing whitespace. Always end files with a newline.
- Keep functions small and single-purpose.
- Validate at system boundaries (user input, external APIs) only — trust internal code.

## Git
- Write commit messages in imperative mood: "Fix bug" not "Fixed bug".
- Keep commits focused — one logical change per commit.
- Use conventional commits format when the project uses it: `type(scope): message`.
