# dotfiles

Personal configuration files for macOS, Debian Linux, and WSL2 (Windows).

This repository handles automated bootstrapping of my core terminal environment and development toolchain. It utilizes a highly modular **Router Pattern**, dynamic symlinking, and strict OS credential store secrets management to provide a seamless, idempotent setup experience across wildly different machines.

---

## What's tracked

| File / Folder | Symlinked to | Purpose |
|------|-------------|---------|
| `zsh/.zshrc` | `~/.zshrc` | Shell config, aliases, secret loading |
| `git/.gitconfig` | `~/.gitconfig` | Git defaults and security settings |
| `git/.gitconfig.local.example` | (template only) | Machine-specific overrides |
| `.editorconfig` | `~/.editorconfig` | Universal editor whitespace/encoding rules |
| `.prettierrc` | `~/.prettierrc` | Default Prettier formatting |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global AI Agent instructions |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code permissions |
| `Brewfile` | (not symlinked) | macOS tool list for `brew bundle` |
| `AGENTS.md` | (repo polyfills) | Repository-specific AI Agent instructions |

### Not tracked (machine-specific)
| File | Purpose |
|------|---------|
| `~/.gitconfig.local` | Credential helper, GPG key, work email overrides |
| `~/.zshrc.local` | Machine-specific shell additions (source from .zshrc if needed) |

---

## Setup — macOS

```bash
# 1. Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone dotfiles
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles

# 3. Run setup
cd ~/dotfiles
bash bootstrap.sh

# 4. Reload shell
source ~/.zshrc

# 5. Authenticate GitHub CLI
gh auth login

# 6. Store API keys in macOS Keychain
security add-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w
# Paste the key value when prompted — it will not echo
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

**Important WSL2 path note:** keep your project files under `~/` (the Linux
filesystem), not under `/mnt/c/`. File I/O from WSL on Windows-mounted drives
is significantly slower.

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

**Security properties of `pass`:**
- Each secret is a GPG-encrypted file
- The password store itself can be tracked in a private git repo for backup
- Works on macOS, Linux, and WSL with no native integration required
- Requires a GPG key (the same key can be used for commit signing)

---

## 🤖 AI & Agents

This repository is optimized to guide and constrain AI coding assistants (like Claude Code, Cursor, and GitHub Copilot). 

### Global Rules (`claude/CLAUDE.md`)
The setup scripts automatically symlink `claude/CLAUDE.md` to `~/.claude/CLAUDE.md`. This sets the baseline global communication, coding, and git standards for any AI agent executing on your system, regardless of what project they are operating in.

### Repository Rules (`AGENTS.md`)
To ensure AI agents do not break the architecture of *these dotfiles*, there is an `AGENTS.md` file at the root. The bootstrap script automatically symlinks this to `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`, and local `CLAUDE.md`. If you ask an AI to "add a new tool to my dotfiles", it automatically reads the rules from its respective file and knows how to:
- Respect the `bootstrap.sh` router pattern.
- Avoid hardcoding secrets.
- Use the `link()` idempotency helper.
- Avoid deprecated tools like `apt-key` or Go PPAs.

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

Commit signing proves commits genuinely came from you.

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

## Adding a new config file

```bash
# Move the file into dotfiles
mv ~/.some-config ~/dotfiles/tool/.some-config

# Create the symlink
ln -s ~/dotfiles/tool/.some-config ~/.some-config

# Add the link() call to both setup.sh and scripts/linux-core.sh

# Commit
cd ~/dotfiles
git add tool/.some-config setup.sh scripts/linux-core.sh
git commit -m "feat(tool): track .some-config"
git push
```

---

## Updating on an existing machine

```bash
cd ~/dotfiles
git pull
# Symlinks update automatically — no re-run needed unless new files were added
source ~/.zshrc
```
