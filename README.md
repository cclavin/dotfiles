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
| `tmux/.tmux.conf` | `~/.tmux.conf` | Tmux config (Catppuccin theme, vi keys) |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global AI Agent instructions |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code permissions |
| `claude/settings.local.json.example` | (template only) | Machine-local Claude permission overrides |
| `claude/commands/` | `~/.claude/commands/` | Custom slash commands (`/pickup`, `/signoff`) |
| `Brewfile` | (not symlinked) | macOS tool list for `brew bundle` |
| `AGENTS.md` | (repo polyfills) | Repository-specific AI Agent instructions |

### Not tracked (machine-specific)
| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Credential helper, GPG key, work email overrides |
| `~/.zshrc.local` | Machine-specific shell additions (auto-sourced by `.zshrc`) |
| `~/.claude/settings.local.json` | Machine-local Claude permission overrides |
| `~/.local/share/dotfiles/state.env` | Installed version, role, migration history |

---

## Setup — macOS

```bash
# 1. Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone dotfiles
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles

# 3. Run setup (use bash explicitly — never sudo)
bash ~/dotfiles/bootstrap.sh --no-cloud

# 4. Reload shell
source ~/.zshrc

# 5. Authenticate GitHub CLI
gh auth login

# 6. Store API keys in macOS Keychain
security add-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w
# Paste the key value when prompted — it will not echo

# 7. Set terminal font to JetBrainsMono Nerd Font (for Starship glyphs)
#    Terminal > Preferences > Profiles > Font
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

# 4. Authenticate GitHub CLI
gh auth login

# 5. Store API keys with pass (GPG-encrypted)
gpg --full-generate-key       # create a key if you don't have one
pass init <your-gpg-key-id>   # initialise the password store
pass insert api-keys/ANTHROPIC_API_KEY
```

---

## Setup — WSL2 (Windows)

WSL2 + Debian/Ubuntu is the recommended Windows environment. It runs the
same Linux toolchain as the Debian setup with no rewrites.

```powershell
# In PowerShell (admin) — enable WSL2 and install Debian
wsl --install -d Debian
# Restart when prompted, then open the Debian terminal
```

```bash
# Inside WSL2 Debian terminal:
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
```

The setup script detects WSL2 and configures the git credential helper to use
**Windows Git Credential Manager** (installed alongside Git for Windows) so you
authenticate once and it works in both Windows and WSL. If Git for Windows is
not installed, it falls back to `pass`.

**Install Node + Claude Code in WSL2:**
```bash
fnm install 20 && fnm use 20
npm install -g @anthropic-ai/claude-code
```

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

```bash
cd ~/dotfiles
git pull
bash bootstrap.sh --no-cloud   # or --cloud if you want cloud tools too
bash bootstrap.sh --audit
```

The bootstrap run:
1. Applies any pending migrations (structural changes between versions)
2. Re-runs platform setup (idempotent — only installs what's missing)
3. Validates the final state

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
bootstrap.sh          ← entrypoint: flags, migrate, OS route, role, validate
  scripts/lib.sh      ← shared helpers (info, link, run, is_dry_run, detect_os)
  scripts/versions.sh ← pinned tool versions (single source of truth)
  scripts/state.sh    ← local state (~/.local/share/dotfiles/state.env)
  scripts/migrate.sh  ← apply pending numbered migrations
  scripts/validate.sh ← audit system state
  scripts/style.sh    ← optional styling (--style enhanced installs Nerd Fonts)
  setup.sh            ← macOS platform setup
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
  migrations/001-init-state.sh
  migrations/002-zshrc-local-support.sh
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

`~/workspace/vault` is created by bootstrap but not managed here. Recommended sync approach is **Syncthing** (free, P2P, no cloud relay) — install separately per machine and point it at `~/workspace/vault`. Not included in dotfiles as it requires per-machine peer configuration.

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
