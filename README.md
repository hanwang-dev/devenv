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
- **Shell** — symlinks `.zshrc` / `.bashrc` with PATH entries for pyenv, Go, and nvm; sets zsh as default (Unix)
- **VS Code** — symlinks `configs/vscode/settings.json` and installs extensions from `configs/vscode/extensions.txt`

## Structure

```
devenv/
├── setup.sh                  # Unix entry point
├── setup.ps1                 # Windows entry point
├── scripts/
│   ├── common.sh             # Shared utilities (logging, OS detection, symlink)
│   ├── macos.sh              # macOS-specific installs
│   ├── ubuntu.sh             # Ubuntu/Mint-specific installs
│   └── configure.sh          # Common post-install configuration
└── configs/
    ├── git/.gitconfig        # Git aliases and editor settings
    ├── shell/.zshrc          # zsh config
    ├── shell/.bashrc         # bash config
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
