#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Make tools installed by user-local installers discoverable during setup.
export PATH="$HOME/.local/bin:$PATH"

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERR]${NC}   $*" >&2; }

command_exists() { command -v "$1" &>/dev/null; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi "mint" /etc/os-release 2>/dev/null; then
        echo "mint"
      else
        echo "ubuntu"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

install_if_missing() {
  local cmd="$1"
  local desc="${2:-$1}"
  local install_fn="$3"
  if command_exists "$cmd"; then
    log_success "$desc already installed"
  else
    log_info "Installing $desc..."
    $install_fn
    log_success "$desc installed"
  fi
}

symlink_config() {
  local src="$1"
  local dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log_success "Already linked: $dst"
    return
  fi
  [ -f "$dst" ] && mv "$dst" "${dst}.bak" && log_warn "Backed up: ${dst}.bak"
  ln -sf "$src" "$dst"
  log_success "Linked: $dst"
}
