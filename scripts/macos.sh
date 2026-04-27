#!/usr/bin/env bash
# macOS package installation

install_homebrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_nvm() {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  set +u
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  set -u
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
    jandedobbeleer/oh-my-posh/oh-my-posh
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

  if ls ~/Library/Fonts/MapleMono-NF-CN-Regular.ttf &>/dev/null; then
    log_success "Maple Mono NF CN already installed"
  else
    log_info "Installing Maple Mono NF CN..."
    local _maple_ver
    _maple_ver=$(curl -fsSL https://api.github.com/repos/subframe7536/maple-font/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -fsSL "https://github.com/subframe7536/maple-font/releases/download/${_maple_ver}/MapleMono-NF-CN.zip" \
      -o /tmp/maple-nf-cn.zip
    unzip -q /tmp/maple-nf-cn.zip -d /tmp/maple-nf-cn
    cp /tmp/maple-nf-cn/*.ttf ~/Library/Fonts/
    rm -rf /tmp/maple-nf-cn /tmp/maple-nf-cn.zip
    unset _maple_ver
    log_success "Maple Mono NF CN installed"
  fi

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
