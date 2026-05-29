# Codex CLI — Global Instructions

These instructions apply to every project. Project-level AGENTS.md files extend or override these.

## Communication
- Be extremely concise. Avoid filler text, apologies, or preamble.
- Never use emojis unless explicitly requested.
- Focus strictly on answering the technical query.
- When referencing files, use the format `filepath:line_number`.

## Coding Practices
- Optimize for readability and maintainability over clever syntax.
- Strictly adhere to SOLID principles and DRY patterns.
- Keep functions and methods small and single-purpose.
- Prefer explicit null-handling and modern language syntax (e.g. async/await).
- Write comments ONLY for complex business logic. Never comment obvious code.

## Version Control (Git)
- Write commit messages using the imperative mood (e.g. "Add feature" not "Added feature").
- Never use `--no-verify` or bypass git hooks without explicit permission.
- Make commits atomic and focused on a single logical change.
- Never force push (`--force`) without checking with the user first.
- Never commit unless explicitly asked.
- Never push unless explicitly asked.

## Safety
- Always ask for permission before performing destructive operations (e.g. `rm -rf`, `git reset --hard`, `DROP TABLE`).
- Never leak API keys. Use OS credential stores (Keychain, pass) or .env files that are explicitly gitignored.
- Confirm before any destructive file operation (deletion, overwrite of uncommitted work).
