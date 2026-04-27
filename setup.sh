#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/scripts/common.sh"

OS="$(detect_os)"
log_info "Detected OS: $OS"

case "$OS" in
  macos)
    source "$SCRIPT_DIR/scripts/macos.sh"
    ;;
  ubuntu|mint)
    source "$SCRIPT_DIR/scripts/ubuntu.sh"
    ;;
  *)
    log_error "Unsupported OS: $OS"
    log_error "Use setup.ps1 for Windows"
    exit 1
    ;;
esac

source "$SCRIPT_DIR/scripts/configure.sh"

echo ""
log_success "Dev environment ready! Restart your terminal to apply shell changes."
