# VS Code / Antigravity Extensions

## Install (PowerShell — run once)

```powershell
# Critical — WSL integration
code --install-extension ms-vscode-remote.remote-wsl

# Theme
code --install-extension catppuccin.catppuccin-vsc

# Go
code --install-extension golang.go

# Python (Ruff — replaces black + flake8 + isort in one tool)
code --install-extension charliermarsh.ruff

# TypeScript / Next.js
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint
code --install-extension bradlc.vscode-tailwindcss

# Quality of life
code --install-extension usernamehw.errorlens
code --install-extension eamodio.gitlens
```

For Antigravity: install via the Extensions panel inside the app (same extension IDs).

## WSL-side extensions (after connecting via Remote WSL)

When VS Code opens a WSL window (`code .` from inside WSL), language extensions
install on the Linux side and have access to WSL-native tools (gopls, ruff, etc.).
The Go and Ruff extensions will prompt to install their LSP binaries automatically.

## AI extensions — keep all, use as needed

Having multiple AI extensions is fine and useful:
- **anthropic.claude-code** — primary; integrates Claude Code CLI session history
- **openai.chatgpt** — review Codex CLI session history directly in the editor
- **saoudrizwan.claude-dev** (Roo/Cline) — useful for autonomous multi-step tasks
- **github.copilot-chat** — inline completions when you want a second opinion
- **google.geminicodeassist** — Google Cloud / GCP-adjacent work

Disable (not uninstall) any that aren't in active use via the Extensions panel
to avoid startup overhead without losing the install.

## Keep

- ms-python.python / pylance / debugpy — Python suite
- ms-vscode-remote.remote-ssh — for stx-devbox-01 SSH access
- ms-vscode-remote.remote-containers — Docker dev containers
- googlecloudtools.cloudcode — GCP integration
- enkia.tokyo-night — kept as fallback theme

## Remove (genuinely unused)

- xdebug.php-debug — not using PHP
