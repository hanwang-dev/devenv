#!/usr/bin/env bash
# Ubuntu / Linux Mint package installation

install_gh() {
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update -q
  sudo apt install -y gh
}

install_go() {
  local version="1.24.2"
  local arch
  arch="$(dpkg --print-architecture)"
  local tarball="go${version}.linux-${arch}.tar.gz"
  curl -fsSL "https://go.dev/dl/${tarball}" -o "/tmp/${tarball}"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/${tarball}"
  rm "/tmp/${tarball}"
}

install_pyenv() {
  curl -fsSL https://pyenv.run | bash
}

install_nvm() {
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
}

install_vscode() {
  curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" \
    | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
    https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  sudo apt update -q
  sudo apt install -y code
}

install_azure_cli() {
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

setup_ubuntu() {
  log_info "=== Ubuntu / Linux Mint Setup ==="

  log_info "Updating apt..."
  sudo apt update -q
  sudo apt install -y \
    curl wget git zsh build-essential \
    libssl-dev libffi-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev \
    fzf \
    tilix                                        # multi-tab terminal

  install_if_missing gh   "GitHub CLI" install_gh
  install_if_missing code "VS Code"    install_vscode
  install_if_missing az   "Azure CLI"  install_azure_cli

  if [ ! -d "$HOME/.pyenv" ]; then
    log_info "Installing pyenv..."
    install_pyenv
    log_success "pyenv installed"
  else
    log_success "pyenv already installed"
  fi

  install_if_missing go "Go" install_go

  if ! command -v zoxide &>/dev/null; then
    log_info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    log_success "zoxide installed"
  else
    log_success "zoxide already installed"
  fi

  if ! command -v oh-my-posh &>/dev/null; then
    log_info "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    log_success "Oh My Posh installed"
  else
    log_success "Oh My Posh already installed"
  fi

  if fc-list | grep -qi "MesloLGM"; then
    log_success "MesloLGM Nerd Font already installed"
  else
    log_info "Installing MesloLGM Nerd Font..."
    oh-my-posh font install meslo
    log_success "MesloLGM Nerd Font installed — set it as your terminal font"
  fi

  for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    local _repo="https://github.com/zsh-users/${_plugin}"
    [ "$_plugin" = "zsh-syntax-highlighting" ] && _repo="${_repo}.git"
    if [ ! -d "$HOME/.zsh/$_plugin" ]; then
      log_info "Installing $_plugin..."
      git clone -q "$_repo" "$HOME/.zsh/$_plugin"
      log_success "$_plugin installed"
    else
      log_success "$_plugin already installed"
    fi
  done
  unset _plugin _repo

  if [ ! -d "$HOME/.nvm" ]; then
    log_info "Installing nvm + Node.js..."
    install_nvm
    nvm install --lts
    nvm use --lts
    log_success "nvm + Node.js installed"
  else
    log_success "nvm already installed"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  fi

  log_info "Installing npm global tools..."
  npm install -g @openai/codex @anthropic-ai/claude-code
  log_success "Codex CLI and Claude Code installed"

  log_success "Ubuntu/Mint setup complete"
}

setup_ubuntu
