#!/usr/bin/env bash
# macOS package installation

install_homebrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_nvm() {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}

setup_macos() {
  log_info "=== macOS Setup ==="

  install_if_missing brew "Homebrew" install_homebrew
  brew update -q

  log_info "Installing CLI tools..."
  local brew_packages=(
    git
    gh
    go
    pyenv
    node          # required for Codex CLI and Claude Code
    azure-cli
    zsh
    zoxide
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
  )
  for pkg in "${brew_packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      log_success "$pkg already installed"
    else
      log_info "Installing $pkg..."
      brew install "$pkg"
      log_success "$pkg installed"
    fi
  done

  log_info "Installing GUI apps..."
  local casks=(
    visual-studio-code
    iterm2            # multi-tab terminal
  )
  for cask in "${casks[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      log_success "$cask already installed"
    else
      log_info "Installing $cask..."
      brew install --cask "$cask"
      log_success "$cask installed"
    fi
  done

  log_info "Installing npm global tools..."
  local npm_packages=(
    "@openai/codex"
    "@anthropic-ai/claude-code"
  )
  for pkg in "${npm_packages[@]}"; do
    npm install -g "$pkg"
    log_success "$pkg installed"
  done

  log_success "macOS setup complete"
}

setup_macos
