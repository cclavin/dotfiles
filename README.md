# dotfiles

Personal configuration files for macOS, Debian Linux, and WSL2 (Windows).

This repository handles automated bootstrapping of my core terminal environment and development toolchain. It uses a modular **router pattern**, composable **machine roles**, a **migration framework**, and an **audit system** to provide a reproducible, idempotent setup across different machines and environments.

---

## What's tracked

| File / Folder | Symlinked to | Purpose |
|------|-------------|---------|
| `zsh/.zshrc` | `~/.zshrc` | Shell config, aliases, secret loading |
| `git/.gitconfig` | `~/.gitconfig` | Git defaults and security settings |
| `git/.gitconfig.local.example` | (template only) | Machine-specific overrides |
| `.editorconfig` | `~/.editorconfig` | Universal editor whitespace/encoding rules |
| `.prettierrc` | `~/.prettierrc` | Default Prettier formatting |
| `starship/starship.toml` | `~/.config/starship.toml` | Starship prompt config |
| `mise/config.toml` | `~/.config/mise/config.toml` | Global runtime versions (Node LTS, Python 3.12) |
| `tmux/.tmux.conf` | `~/.tmux.conf` | Tmux config (Catppuccin theme, vi keys) |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global AI Agent instructions |
| `claude/settings.json.example` | (template only) | Claude Code base config — copied to `~/.claude/settings.json` on first run |
| `claude/settings.local.json.example` | (template only) | Machine-local Claude permission overrides |
| `claude/commands/` | `~/.claude/commands/` | Custom slash commands (`/pickup`, `/signoff`) |
| `mcp/servers/*.json` | (source of truth) | Canonical MCP server definitions |
| `mcp/registrations/*.json` | (source of truth) | Per-tool MCP server lists |
| `Brewfile` | (not symlinked) | macOS tool list for `brew bundle` |
| `AGENTS.md` | (repo polyfills) | Repository-specific AI Agent instructions |

### Not tracked (machine-specific)
| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Credential helper, GPG key, work email overrides |
| `~/.zshrc.local` | Machine-specific shell additions (auto-sourced by `.zshrc`) |
| `~/.claude/settings.json` | Claude Code config (MCP servers merged in by `mcp/deploy.py`) |
| `~/.claude/settings.local.json` | Machine-local Claude permission overrides |
| `mcp/env` | MCP server secrets — copy from `mcp/env.example` and fill in |
| `mcp/local/registrations/*.json` | Private/machine-specific MCP servers (never committed) |
| `~/.local/share/dotfiles/state.env` | Installed version, role, migration history |

**Symlink contract:** tracked config files are symlinked into `$HOME`, not
copied. Editing `~/.zshrc` and editing `dotfiles/zsh/.zshrc` are the same
operation -- both touch the committed file. Anything that varies per machine
(paths, exports, personal aliases) belongs in `~/.zshrc.local`, not in
`zsh/.zshrc` directly. The same pattern applies across the repo: use
`~/.gitconfig.local` for git and `~/.claude/settings.local.json` for Claude.

---

## Setup — macOS

```bash
# 1. Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone dotfiles
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles

# 3. Run setup (use bash explicitly — never sudo)
bash ~/dotfiles/bootstrap.sh --no-cloud

# 4. Install all Homebrew tools
cd ~/dotfiles && brew bundle

# 5. Reload shell
source ~/.zshrc

# 6. Install runtimes (Node LTS + Python 3.12)
mise install

# 7. Authenticate GitHub CLI
gh auth login

# 8. Store API keys in macOS Keychain
security add-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w
# Paste the key value when prompted — it will not echo

# 9. Set up MCP servers (copy env file and fill in API keys first)
cp ~/dotfiles/mcp/env.example ~/dotfiles/mcp/env
$EDITOR ~/dotfiles/mcp/env   # fill in keys
bash ~/dotfiles/scripts/mcp-setup.sh

# 10. Set terminal font to JetBrainsMono Nerd Font (for Starship glyphs)
#     Terminal > Preferences > Profiles > Font
```

---

## Setup — Debian / Ubuntu (native)

```bash
# 1. Clone dotfiles
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles

# 2. Run setup (installs packages, creates symlinks, sets up git)
cd ~/dotfiles
bash bootstrap.sh

# 3. Reload shell
source ~/.zshrc   # or: exec zsh

# 4. Install runtimes (Node LTS + Python 3.12)
mise install

# 5. Authenticate GitHub CLI
gh auth login

# 6. Store API keys with pass (GPG-encrypted)
gpg --full-generate-key       # create a key if you don't have one
pass init <your-gpg-key-id>   # initialise the password store
pass insert api-keys/ANTHROPIC_API_KEY

# 7. Set up MCP servers
cp ~/dotfiles/mcp/env.example ~/dotfiles/mcp/env
$EDITOR ~/dotfiles/mcp/env
bash ~/dotfiles/scripts/mcp-setup.sh
```

---

## Setup — WSL2 (Windows)

WSL2 + Ubuntu is the recommended Windows dev environment. It runs the same
Linux toolchain as the native Linux setup with no rewrites.

### Prerequisites (Windows side, before opening WSL)

1. **Install Git for Windows** — provides the Git Credential Manager that WSL
   uses for `gh auth` and GitHub pushes. Without it, you'll need to set up GPG
   and `pass` manually inside WSL.
2. **Enable WSL2** (PowerShell as admin):
   ```powershell
   wsl --install          # installs Ubuntu by default; restart when prompted
   ```

### Bootstrap (inside WSL Ubuntu terminal)

```bash
# 1. Install git and curl if not present (minimal Ubuntu images may omit them)
sudo apt-get update && sudo apt-get install -y git curl

# 2. If you have an Obsidian vault on Windows, export its path now so bootstrap
#    creates a symlink instead of an empty directory. Replace with your actual path.
export WINDOWS_VAULT_PATH="/mnt/c/Users/<YourName>/Documents/workspace/vault"
# Also persist it for future shells:
echo "export WINDOWS_VAULT_PATH=\"$WINDOWS_VAULT_PATH\"" >> ~/.zshrc.local

# 3. Clone dotfiles
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles

# 4. Run bootstrap
#    --role wsl-dev  → installs core tools + cloud stack (Go, GCP, Terraform; skips Docker)
#    --no-cloud      → prevents the interactive cloud prompt, which wsl-dev already handles
cd ~/dotfiles
bash bootstrap.sh --role wsl-dev --no-cloud
```

> **Note:** bootstrap ends with a validation run. mise and uv will show as
> failing because `~/.local/bin` is not on `PATH` in the bootstrap bash session.
> This is expected — re-run `--audit` after reloading your shell (step 5).

```bash
# 5. Reload shell (activates mise, sets full PATH)
exec zsh

# 6. Install runtimes
mise install

# 7. Authenticate GitHub CLI
gh auth login

# 8. Install Claude Code
npm install -g @anthropic-ai/claude-code

# 9. Set up MCP servers
cp ~/dotfiles/mcp/env.example ~/dotfiles/mcp/env
$EDITOR ~/dotfiles/mcp/env   # fill in API keys
bash ~/dotfiles/scripts/mcp-setup.sh

# 10. Confirm everything is clean
bash ~/dotfiles/bootstrap.sh --audit
```

### Credential management

The bootstrap auto-detects Git for Windows at
`/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe`. If found,
`~/.gitconfig.local` is written to use it — you authenticate once and it works
in both Windows and WSL.

If Git for Windows is not installed, the credential helper section in
`~/.gitconfig.local` is commented out with instructions. You can either install
Git for Windows and re-run bootstrap, or set up GPG + `pass` inside WSL.

### Partially initialized machine

If you've previously set up tools manually in WSL:

- **Existing `~/.zshrc`** — the `link()` helper backs it up to `~/.zshrc.bak`
  and replaces it with the tracked version. Move any custom config from
  `~/.zshrc.bak` into `~/.zshrc.local` (auto-sourced at the end of `.zshrc`).
- **Existing Node (nvm/fnm)** — mise takes over as the runtime manager. Run
  `mise use node@<version>` in any project that needs a specific version.
- **Re-running bootstrap** is always safe — all scripts are idempotent.

---

## Bootstrap flags

`bootstrap.sh` supports flags for non-interactive and CI use. Without flags, it behaves interactively (same as before).

| Flag | Effect |
|------|--------|
| `--role <name>` | Apply a machine role after platform setup |
| `--cloud` | Install cloud toolchain without prompting |
| `--no-cloud` | Skip cloud toolchain without prompting |
| `--yes`, `-y` | Auto-accept all interactive prompts |
| `--dry-run` | Preview what would be installed — no changes made |
| `--audit` | Validate current system state and exit |
| `--style minimal\|enhanced` | Apply optional styling (Nerd Fonts etc.) |
| `--help` | Show usage |

```bash
# Preview what a fresh setup would do
./bootstrap.sh --dry-run --no-cloud

# Non-interactive WSL setup with cloud tools
./bootstrap.sh --role wsl-dev --yes

# Check if an existing machine is correctly configured
./bootstrap.sh --audit
```

---

## Machine roles

Roles are composable profiles that orchestrate the platform scripts. They are additive — running a role on an already-set-up machine is safe (all scripts are idempotent).

| Role | What it installs |
|------|-----------------|
| `wsl-dev` | Core Linux tools + cloud stack (Docker skipped — Docker Desktop handles it) |
| `linux-dev` | Core Linux tools only |
| `macos-workstation` | macOS dotfiles + all Homebrew packages |
| `cloud-admin` | Core Linux tools + full cloud stack (Go, Docker, GCP CLI, Terraform) |

```bash
./bootstrap.sh --role cloud-admin --yes
```

Role state is saved to `~/.local/share/dotfiles/state.env` and used by `--audit` to validate role-specific requirements.

---

## Upgrading an existing machine

### 1. Check for local modifications before pulling

```bash
cd ~/dotfiles
git status
git diff          # review any changes to tracked files
```

If tracked files (e.g. `zsh/.zshrc`) have local modifications, handle them
before pulling -- see the symlink contract note above. Machine-specific changes
belong in `~/.zshrc.local`; repo-worthy changes should be committed first.

### 2. Pull and re-bootstrap

A bare `git pull` is not enough -- it does not run migrations, create new
symlinks, or install new tools. Always follow with bootstrap.

```bash
git pull

# macOS
bash bootstrap.sh --no-cloud

# Linux / WSL -- pass the same role used at initial setup
# (check your role: grep ROLE ~/.local/share/dotfiles/state.env)
bash bootstrap.sh --role wsl-dev --no-cloud
```

The bootstrap run:
1. Applies any pending migrations (structural changes between versions)
2. Re-runs platform setup (idempotent -- only installs what is missing)
3. Validates the final state

### 3. Reload and pick up runtime changes

```bash
exec zsh           # reload shell to activate new PATH, mise shims, etc.
mise install       # install any newly declared runtimes
bash bootstrap.sh --audit
```

> On Linux/WSL, the end-of-bootstrap validation runs before the shell reloads,
> so mise and uv may appear as failing. This is expected -- the audit after
> `exec zsh` is the authoritative check.

---

## Audit / validation

Check that a machine is correctly configured without making changes:

```bash
./bootstrap.sh --audit
# or
bash scripts/validate.sh
```

Validates:
- Required commands are installed
- All config symlinks are in place
- Git config is readable and `~/.gitconfig.local` exists
- Workspace directories exist (`~/workspace/code`, `~/workspace/vault`)
- Role-specific tools (if a role is stored in state)

---

## Architecture

```
bootstrap.sh               ← entrypoint: flags, migrate, OS route, role, validate
  scripts/lib.sh           ← shared helpers (info, link, run, is_dry_run, detect_os)
  scripts/versions.sh      ← pinned tool versions (single source of truth)
  scripts/state.sh         ← local state (~/.local/share/dotfiles/state.env)
  scripts/migrate.sh       ← apply pending numbered migrations
  scripts/validate.sh      ← audit system state
  scripts/style.sh         ← optional styling (--style enhanced installs Nerd Fonts)
  scripts/mcp-setup.sh     ← source mcp/env secrets and run mcp/deploy.py
  setup.sh                 ← macOS platform setup
  scripts/linux-core.sh    ← Linux/WSL core tools + symlinks
  scripts/linux-cloud.sh   ← cloud toolchain dispatcher
    scripts/cloud/go.sh
    scripts/cloud/docker.sh
    scripts/cloud/gcp.sh
    scripts/cloud/terraform.sh
  roles/wsl-dev.sh
  roles/linux-dev.sh
  roles/macos-workstation.sh
  roles/cloud-admin.sh
  mise/config.toml          ← global runtime versions (Node, Python)
  mcp/deploy.py             ← merge MCP server configs into each tool's live config
  mcp/servers/*.json        ← canonical server definitions
  mcp/registrations/*.json  ← per-tool server lists (claude-code, gemini-cli, etc.)
  mcp/local/                ← machine-local private servers (gitignored)
  migrations/001-init-state.sh
  migrations/002-zshrc-local-support.sh
  migrations/003-mise-activation.sh
```

---

## Secrets — how they work

Secrets are loaded at shell startup from the OS credential store — never from
files on disk.

| Platform | Store | How to add a secret |
|----------|-------|-------------------|
| macOS | Keychain | `security add-generic-password -a "$USER" -s KEY_NAME -w` |
| Linux (desktop) | GNOME libsecret | `secret-tool store --label="KEY_NAME" application KEY_NAME` |
| Linux / WSL | pass (GPG) | `pass insert api-keys/KEY_NAME` |
| Windows (WSL) | Windows Credential Manager | via Git Credential Manager, or use pass |

`~/.zshrc` calls `_load_secret KEY_NAME` which queries the appropriate store
for the current OS. If no store is available the variable is simply unset — no
error, no plain-text fallback.

---

## AI & Agents

This repository is optimized to guide and constrain AI coding assistants (Claude Code, Cursor, GitHub Copilot).

### Global Rules (`claude/CLAUDE.md`)
The setup scripts symlink `claude/CLAUDE.md` to `~/.claude/CLAUDE.md`, setting baseline communication, coding, and git standards for any AI agent executing on the machine.

### Repository Rules (`AGENTS.md`)
`AGENTS.md` at the repo root is polyfilled to `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, and local `CLAUDE.md`. It encodes 11 architectural rules including the router pattern, shared library usage, version pin management, state tracking, and migration conventions.

### Scaffolding AI rules into projects (`bin/ai-init`)
```bash
ai-init go       # compile global standards + Go template into .cursorrules
ai-init pios --stack go-api  # fetch rules from github.com/cclavin/PIOS
```

---

## Machine-local customization

Each tracked config file has a corresponding `.local` file that is sourced or
included automatically and is never committed. This is the correct place for
anything that varies per machine -- never edit the tracked file directly for
machine-specific needs.

| Tracked file | Local override | Auto-loaded? |
|---|---|---|
| `zsh/.zshrc` | `~/.zshrc.local` | Yes -- sourced at end of `.zshrc` |
| `git/.gitconfig` | `~/.gitconfig.local` | Yes -- via `[include]` in `.gitconfig` |
| `claude/settings.json.example` | `~/.claude/settings.json` + `settings.local.json` | Yes -- Claude Code merges both |

Common things that belong in `~/.zshrc.local`:

```bash
# Work-specific environment
export WORK_EMAIL="you@company.com"

# WSL vault path
export WINDOWS_VAULT_PATH="/mnt/c/Users/You/Documents/workspace/vault"

# Machine-specific PATH additions
export PATH="$PATH:/opt/some-tool/bin"

# Aliases that only make sense on this machine
alias proj='cd ~/workspace/code/myproject'
```

---

## Machine-local git config (`~/.gitconfig.local`)

`~/.gitconfig` is tracked here and shared across all machines. Machine-specific
settings (credential helper, GPG key ID, work email) live in `~/.gitconfig.local`,
which is included by `~/.gitconfig` but is never committed.

The setup scripts create `~/.gitconfig.local` automatically. To customise it:
```bash
# See the template for all options:
cat ~/dotfiles/git/.gitconfig.local.example

# Edit your local copy:
$EDITOR ~/.gitconfig.local
```

---

## GPG commit signing (optional)

```bash
# 1. Generate a key
gpg --full-generate-key
# Choose: RSA and RSA, 4096 bits, no expiry (or set one)

# 2. Get your key ID
gpg --list-secret-keys --keyid-format=long
# Look for:  sec   rsa4096/XXXXXXXXXXXXXXXX

# 3. Add to ~/.gitconfig.local
echo '[user]' >> ~/.gitconfig.local
echo '  signingkey = XXXXXXXXXXXXXXXX' >> ~/.gitconfig.local
echo '[commit]' >> ~/.gitconfig.local
echo '  gpgsign = true' >> ~/.gitconfig.local

# 4. Add public key to GitHub
gpg --armor --export XXXXXXXXXXXXXXXX | gh gpg-key add -
```

---

## Workspace

All machines use `~/workspace/code` as the canonical project root. The `sync-code` shell function fetches and shows status for every repo in that directory, flags uncommitted changes, then pulls on confirmation:

```bash
sync-code
```

Use `cw` to jump to the workspace root from anywhere:

```bash
cw   # cd ~/workspace/code
```

### Obsidian vault

`~/workspace/vault` is created by bootstrap. On WSL2, point it at the Windows vault via a symlink so both Obsidian (Windows) and the terminal (WSL) share the same files with no sync layer:

```bash
# In WSL — replace with your actual vault path in Windows
ln -sf "/mnt/c/Users/<user>/Documents/workspace/vault" ~/workspace/vault
```

Add `WINDOWS_VAULT_PATH` to `~/.zshrc.local` so the path is documented per-machine:
```bash
export WINDOWS_VAULT_PATH="/mnt/c/Users/<user>/Documents/workspace/vault"
```

The vault git repo (if present) is local-only — no remote is configured by design.

---

## Runtime management (mise)

`mise` is the polyglot runtime manager. It replaces `fnm` for Node and adds Python version management. The global config lives at `mise/config.toml` (symlinked to `~/.config/mise/config.toml`).

```bash
mise install          # install all runtimes declared in mise/config.toml
mise ls               # list installed versions
mise use node@22      # pin a specific version in the current project
```

Per-project overrides: add a `.mise.toml` or `.tool-versions` file at the project root. mise respects these automatically when you `cd` into the directory.

`fnm` remains installed as a fallback on machines not yet migrated. The `.zshrc` activates mise if present, fnm otherwise. Once all machines are on mise, fnm will be removed.

**Trust:** `mise/config.toml` is symlinked into the dotfiles repo. mise treats
symlinks that resolve outside `~/.config/mise/` as untrusted and will refuse to
load them until approved. Bootstrap handles this automatically by running
`mise trust ~/.config/mise/config.toml` after creating the symlink. If you ever
see a trust error manually, run:

```bash
mise trust ~/.config/mise/config.toml
```

---

## Python projects (uv)

`uv` manages Python packages, virtual environments, and ephemeral CLI tools.

```bash
# Start a new Python project
uv init myproject
cd myproject
uv add requests        # add a dependency
uv sync                # install from lockfile

# Run a Python script with inline dependencies (no venv needed)
uv run script.py

# Run a Python CLI tool without installing it permanently
uvx ruff check .
uvx mypy src/
```

For projects that need a specific Python version, add a `.python-version` file:
```bash
echo "3.11" > .python-version
uv sync    # uv installs 3.11 automatically if needed
```

---

## MCP servers

MCP server definitions are tracked in `mcp/servers/*.json`. Per-tool registrations (which servers go to which AI tool) live in `mcp/registrations/*.json`. The deploy script merges them into each tool's live config.

### First-time setup

```bash
# Copy the secrets template and fill in API keys
cp ~/dotfiles/mcp/env.example ~/dotfiles/mcp/env
$EDITOR ~/dotfiles/mcp/env

# Deploy to all tools
bash ~/dotfiles/scripts/mcp-setup.sh

# Preview without writing
bash ~/dotfiles/scripts/mcp-setup.sh --dry-run

# Deploy to a single tool only
bash ~/dotfiles/scripts/mcp-setup.sh --tool claude-code
```

### Private / machine-local servers

Servers you don't want committed (internal tools, personal integrations) go in `mcp/local/registrations/<tool>.json`. This directory is gitignored. The deploy script merges local servers with tracked ones automatically.

```bash
mkdir -p ~/dotfiles/mcp/local/registrations
# Create mcp/local/registrations/claude-code.json with your private servers
# Same format as mcp/registrations/claude-code.json
bash ~/dotfiles/scripts/mcp-setup.sh
```

### Rotating a key

```bash
# Update mcp/env with the new key, then:
bash ~/dotfiles/scripts/mcp-setup.sh --force --server stripe
```

---

## Adding a new config file

```bash
# 1. Move the file into dotfiles
mv ~/.some-config ~/dotfiles/tool/.some-config

# 2. Add link() calls in both setup.sh (macOS) and scripts/linux-core.sh (Linux)
#    The link() helper is in scripts/lib.sh and is already available in both scripts
link "$DOTFILES/tool/.some-config" "$HOME/.some-config"

# 3. Commit
cd ~/dotfiles
git add tool/.some-config setup.sh scripts/linux-core.sh
git commit -m "feat(tool): track .some-config"
git push
```

---

## Running tests

```bash
# Run the full test suite (Docker preferred, WSL2 fallback)
bash tests/run.sh

# Or directly (requires a bash environment)
bash tests/test.sh
```

Tests cover: shared library functions, version pin format, state get/set/upsert,
migration apply/skip/halt, bootstrap flag parsing, end-to-end dry-run, and
validation output — without performing any real installs.
