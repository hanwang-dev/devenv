#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/common.sh"

SCHEDULE=false
CRON_SCHEDULE="0 9 * * 1"   # every Monday at 09:00

usage() {
  cat <<EOF
Usage: $(basename "$0") [--schedule [cron-expr]]

  --schedule [cron-expr]   Install a cron job to run upgrades automatically.
                           Default schedule: "$CRON_SCHEDULE" (Mon 09:00)
                           Example: --schedule "0 9 * * 1,4"

  Without flags: run upgrade immediately.
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --schedule)
        SCHEDULE=true
        if [[ ${2-} && ${2} != --* ]]; then
          CRON_SCHEDULE="$2"
          shift
        fi
        ;;
      -h|--help) usage; exit 0 ;;
      *) log_error "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done
}

# ── Per-platform upgrade logic ────────────────────────────────────────────────

upgrade_macos() {
  log_info "Upgrading Homebrew packages..."
  brew update -q
  brew upgrade
  brew upgrade --cask visual-studio-code iterm2 || true
  brew cleanup -q
  log_success "Homebrew packages upgraded"
}

upgrade_ubuntu() {
  log_info "Upgrading apt packages..."
  sudo apt update -q
  sudo apt upgrade -y
  sudo apt autoremove -y -q
  log_success "apt packages upgraded"

  log_info "Upgrading GitHub CLI..."
  sudo apt install -y --only-upgrade gh || true

  log_info "Upgrading Go..."
  local installed_ver latest_ver
  installed_ver="$( go version 2>/dev/null | grep -oP 'go\K[0-9.]+' || echo "0" )"
  latest_ver="$(curl -fsSL https://go.dev/VERSION?m=text | head -1 | sed 's/go//')"
  if [ "$installed_ver" != "$latest_ver" ]; then
    log_info "Upgrading Go $installed_ver → $latest_ver"
    local arch tarball
    arch="$(dpkg --print-architecture)"
    tarball="go${latest_ver}.linux-${arch}.tar.gz"
    curl -fsSL "https://go.dev/dl/${tarball}" -o "/tmp/${tarball}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "/tmp/${tarball}"
    rm "/tmp/${tarball}"
    log_success "Go upgraded to $latest_ver"
  else
    log_success "Go $installed_ver is already latest"
  fi
}

upgrade_pyenv() {
  if [ -d "$HOME/.pyenv" ]; then
    log_info "Upgrading pyenv..."
    git -C "$HOME/.pyenv" pull -q
    log_success "pyenv upgraded"
  fi
}

upgrade_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    log_info "Upgrading nvm..."
    local latest_nvm
    latest_nvm="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
      | grep '"tag_name"' | grep -oP 'v[0-9.]+')"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${latest_nvm}/install.sh" | bash
    source "$NVM_DIR/nvm.sh"
    log_info "Upgrading Node.js to latest LTS..."
    nvm install --lts
    nvm alias default lts/*
    log_success "nvm and Node.js upgraded"
  fi
}

upgrade_npm_globals() {
  log_info "Upgrading global npm packages..."
  npm update -g @openai/codex @anthropic-ai/claude-code
  log_success "Codex CLI and Claude Code upgraded"
}

upgrade_azure_cli() {
  if command_exists az; then
    log_info "Upgrading Azure CLI..."
    az upgrade --yes --all 2>/dev/null || true
    log_success "Azure CLI upgraded"
  fi
}

# ── Scheduling ────────────────────────────────────────────────────────────────

install_cron() {
  local upgrade_path="$SCRIPT_DIR/upgrade.sh"
  local log_path="$HOME/.devenv-upgrade.log"
  local cron_entry="$CRON_SCHEDULE $upgrade_path >> $log_path 2>&1"
  local tmp
  tmp="$(mktemp)"

  # Remove any existing devenv upgrade entry, then append new one
  crontab -l 2>/dev/null | grep -v "devenv/upgrade.sh" > "$tmp" || true
  echo "# devenv auto-upgrade" >> "$tmp"
  echo "$cron_entry" >> "$tmp"
  crontab "$tmp"
  rm "$tmp"

  log_success "Cron job installed: $CRON_SCHEDULE"
  log_info  "Logs will be written to: $log_path"
  log_info  "To remove: crontab -e and delete the devenv lines"
}

# ── Main ──────────────────────────────────────────────────────────────────────

run_upgrade() {
  log_info "=== devenv upgrade $(date '+%Y-%m-%d %H:%M') ==="
  local os
  os="$(detect_os)"

  case "$os" in
    macos)        upgrade_macos ;;
    ubuntu|mint)  upgrade_ubuntu ;;
  esac

  upgrade_pyenv
  upgrade_nvm
  upgrade_npm_globals
  upgrade_azure_cli

  log_success "All tools upgraded"
}

parse_args "$@"

if $SCHEDULE; then
  install_cron
else
  run_upgrade
fi
