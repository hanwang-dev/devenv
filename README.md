# devenv

Cross-platform dev environment setup for macOS, Ubuntu, Linux Mint, and Windows.

## What it installs

| Tool | Description |
|------|-------------|
| Git | Version control |
| GitHub CLI (`gh`) | GitHub from the terminal |
| VS Code | Editor + extensions + settings |
| Python | via `pyenv` / `pyenv-win` |
| Go | Latest stable release |
| Node.js | via `nvm` (Unix) / winget LTS (Windows) |
| Codex CLI | `@openai/codex` via npm |
| Claude Code | `@anthropic-ai/claude-code` via npm |
| Azure CLI | `az` |
| Terminal | iTerm2 (macOS) · Tilix (Ubuntu/Mint) · Windows Terminal |
| zoxide | Frecency-based directory jumping — `z <dir>` instead of `cd` |
| fzf | Fuzzy finder — Ctrl+R history, Ctrl+T files, Alt+C cd into subdir |
| zsh-autosuggestions | Fish-style inline history completion (Unix) |
| zsh-syntax-highlighting | Real-time command syntax highlighting (Unix) |

## Usage

### macOS / Ubuntu / Linux Mint

```bash
git clone https://github.com/yourname/devenv.git
cd devenv
bash setup.sh
```

### Windows

Run in an **Administrator PowerShell**:

```powershell
git clone https://github.com/yourname/devenv.git
cd devenv
.\setup.ps1
```

> Windows requires `winget` (ships with Windows 11; install [App Installer](https://aka.ms/getwinget) on Windows 10).

## What gets configured

- **Git** — prompts for name/email on first run; applies shared aliases and settings from `configs/git/.gitconfig`
- **Shell** — symlinks `.zshrc` / `.bashrc` with PATH entries for pyenv, Go, and nvm; sets zsh as default (Unix); links `profile.ps1` as the PowerShell profile (Windows)
- **CLI productivity** — zoxide for smart directory jumping, fzf for fuzzy search, zsh-autosuggestions + zsh-syntax-highlighting on Unix, PSReadLine history predictions + PSFzf keybindings on Windows
- **VS Code** — symlinks `configs/vscode/settings.json` and installs extensions from `configs/vscode/extensions.txt`

## Upgrading

### Run manually

```bash
# Unix
bash upgrade.sh

# Windows (Administrator PowerShell)
.\upgrade.ps1
```

### Schedule automatic upgrades

**Unix** — installs a cron job (default: every Monday at 09:00):

```bash
bash upgrade.sh --schedule
# custom schedule (Mon + Thu at 09:00):
bash upgrade.sh --schedule "0 9 * * 1,4"
```

Logs are written to `~/.devenv-upgrade.log`. To remove: `crontab -e` and delete the devenv lines.

**Windows** — registers a Task Scheduler job:

```powershell
.\upgrade.ps1 -Schedule
# custom day/time:
.\upgrade.ps1 -Schedule -ScheduleDaysOfWeek "Monday,Thursday" -ScheduleTime "09:00"
```

Logs are written to `~\.devenv-upgrade.log`. To remove: `Unregister-ScheduledTask -TaskName devenv-auto-upgrade`.

### What gets upgraded

| Component | macOS | Ubuntu/Mint | Windows |
|-----------|-------|-------------|---------|
| System packages | `brew upgrade` | `apt upgrade` | `winget upgrade` |
| Go | brew | latest tarball from go.dev | winget |
| pyenv | `git pull` | `git pull` | `git pull` |
| nvm + Node.js | latest nvm + LTS | latest nvm + LTS | — |
| Codex CLI | `npm update -g` | `npm update -g` | `npm update -g` |
| Claude Code | `npm update -g` | `npm update -g` | `npm update -g` |
| Azure CLI | `az upgrade` | `az upgrade` | `az upgrade` |
| zoxide | brew | — | winget |
| fzf | brew | — | winget |

## Structure

```
devenv/
├── setup.sh                  # Unix entry point
├── setup.ps1                 # Windows entry point
├── upgrade.sh                # Unix upgrade + cron scheduler
├── upgrade.ps1               # Windows upgrade + Task Scheduler
├── scripts/
│   ├── common.sh             # Shared utilities (logging, OS detection, symlink)
│   ├── macos.sh              # macOS-specific installs
│   ├── ubuntu.sh             # Ubuntu/Mint-specific installs
│   └── configure.sh          # Common post-install configuration
└── configs/
    ├── git/.gitconfig        # Git aliases and editor settings
    ├── shell/.zshrc          # zsh config (macOS/Linux)
    ├── shell/.bashrc         # bash config
    ├── shell/profile.ps1     # PowerShell profile (Windows)
    └── vscode/
        ├── settings.json     # Editor, Python, Go settings
        └── extensions.txt    # VS Code extensions list
```

## Customization

**Add a package** — edit the relevant platform script (`scripts/macos.sh`, `scripts/ubuntu.sh`, or `setup.ps1`).

**Add a VS Code extension** — append the extension ID to `configs/vscode/extensions.txt`.

**Modify shell config** — edit `configs/shell/.zshrc` or `.bashrc`; changes apply immediately since they are symlinked.

## Idempotent

Safe to run multiple times — already-installed tools are skipped, existing dotfiles are backed up with a `.bak` suffix before being replaced.
