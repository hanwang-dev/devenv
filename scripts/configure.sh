#!/usr/bin/env bash
# Common post-install configuration: git identity, dotfiles, VS Code extensions

DEVENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

configure_git_identity() {
  local current_name current_email
  current_name="$(git config --global user.name 2>/dev/null || true)"
  current_email="$(git config --global user.email 2>/dev/null || true)"

  if [ -z "$current_name" ]; then
    read -rp "Git user name: " git_name
    git config --global user.name "$git_name"
  else
    log_success "Git name already set: $current_name"
  fi

  if [ -z "$current_email" ]; then
    read -rp "Git email: " git_email
    git config --global user.email "$git_email"
  else
    log_success "Git email already set: $current_email"
  fi
}

link_dotfiles() {
  local config_dir="$DEVENV_DIR/configs"

  symlink_config "$config_dir/git/.gitconfig"   "$HOME/.gitconfig"

  mkdir -p "$HOME/.config/wezterm"
  symlink_config "$config_dir/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

  if [ "$SHELL" = "$(command -v zsh)" ] || command_exists zsh; then
    symlink_config "$config_dir/shell/.zshrc"   "$HOME/.zshrc"
  fi
  symlink_config "$config_dir/shell/.bashrc"    "$HOME/.bashrc"

  local vscode_dir
  case "$(detect_os)" in
    macos)  vscode_dir="$HOME/Library/Application Support/Code/User" ;;
    *)      vscode_dir="$HOME/.config/Code/User" ;;
  esac
  mkdir -p "$vscode_dir"
  symlink_config "$config_dir/vscode/settings.json" "$vscode_dir/settings.json"
}

install_vscode_extensions() {
  if ! command_exists code; then
    log_warn "VS Code CLI not found — skipping extension install"
    return
  fi
  log_info "Installing VS Code extensions..."
  while IFS= read -r ext || [ -n "$ext" ]; do
    [[ "$ext" =~ ^#|^$ ]] && continue
    code --install-extension "$ext" --force
  done < "$DEVENV_DIR/configs/vscode/extensions.txt"
  log_success "VS Code extensions installed"
}

set_default_shell_zsh() {
  if command_exists zsh && [ "$SHELL" != "$(command -v zsh)" ]; then
    log_info "Setting zsh as default shell..."
    chsh -s "$(command -v zsh)"
    log_success "Default shell set to zsh (restart terminal to apply)"
  fi
}

configure() {
  log_info "=== Common Configuration ==="
  link_dotfiles          # symlink first so git reads our gitconfig
  configure_git_identity
  install_vscode_extensions
  set_default_shell_zsh
  log_success "Configuration complete"
}

configure
