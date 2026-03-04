# Dotfiles Agent Instructions

You are an AI assistant helping to maintain this dotfiles repository. When the user asks you to modify or add configurations, please strictly adhere to these architectural standards:

1. **Router Pattern**: The primary entry point is `bootstrap.sh`. Do not add extensive OS-specific logic directly to the bootstrap script. Instead, isolate logic inside `setup.sh` (macOS), `scripts/linux-core.sh` (Debian/WSL base), and `scripts/linux-cloud.sh` (Debian/WSL toolchain).
2. **Secrets Rule**: NEVER store, hardcode, or commit secrets, tokens, or API keys in plain text in this repository. Secrets must always be dynamically requested from the OS credential store (macOS Keychain, Linux libsecret, pass, or Windows Credential Manager).
3. **Symlinking Strategy**: When instructed to track a new configuration file, place it in the appropriate tool directory (e.g., `zsh/`, `git/`) and symlink it in both `setup.sh` and `scripts/linux-core.sh` using the provided `link()` helper function.
4. **Idempotency**: All scripts must be safely re-runnable. Always check if a package is installed (`command -v`), a directory exists, or a config line is already present before installing or mutating state. Avoid operations that fail if run twice.
5. **No PPAs for Go**: When managing Go on Debian/Ubuntu, strictly use the authoritative `linux-amd64.tar.gz` script flow, never use `apt` or PPAs.
6. **Modern APT Keyrings**: Any new debian apt repositories must use the modern `/etc/apt/keyrings/` structure via `gpg --dearmor`. Do not use the deprecated `apt-key` command.
7. **Absolute/Parent Paths**: Always reference relative files dynamically using `$DOTFILES/...` as established in the script headers (e.g. `DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`).
