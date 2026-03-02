# dotfiles

Personal macOS configuration files, tracked with git and symlinked to their expected locations.

## What's tracked

| File | Symlinked to |
|------|-------------|
| `zsh/.zshrc` | `~/.zshrc` |
| `git/.gitconfig` | `~/.gitconfig` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `claude/settings.json` | `~/.claude/settings.json` |

## Setting up on a new machine

```bash
git clone https://github.com/cclavin/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup.sh
./setup.sh
```

Then store secrets in the macOS Keychain (never in files):
```bash
security add-generic-password -a "$USER" -s ANTHROPIC_API_KEY -w
```

## Adding a new config file

```bash
cp ~/.some-config ~/dotfiles/tool/.some-config
rm ~/.some-config
ln -s ~/dotfiles/tool/.some-config ~/.some-config
```

Then commit:
```bash
cd ~/dotfiles
git add tool/.some-config
git commit -m "feat(tool): add initial config"
git push
```
