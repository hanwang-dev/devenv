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
  # nvm uses unbound variables internally — disable -u while sourcing
  set +u
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  set -u
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

install_wezterm() {
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list > /dev/null
  sudo apt update -q
  sudo apt install -y wezterm
}

install_fzf() {
  local arch
  case "$(dpkg --print-architecture)" in
    amd64) arch="amd64" ;;
    arm64) arch="arm64" ;;
    *)     arch="$(dpkg --print-architecture)" ;;
  esac
  local version
  version="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
    | grep -o '"tag_name": *"[^"]*"' | grep -o '[0-9][^"]*')"
  mkdir -p ~/.local/bin
  curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_${arch}.tar.gz" \
    | tar -xz -C ~/.local/bin fzf
}

setup_ubuntu() {
  log_info "=== Ubuntu / Linux Mint Setup ==="

  log_info "Updating apt..."
  sudo apt update -q
  sudo apt install -y \
    curl wget git zsh build-essential \
    libssl-dev libffi-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev \
    p7zip-full

  install_if_missing gh      "GitHub CLI" install_gh
  install_if_missing code    "VS Code"    install_vscode
  install_if_missing az      "Azure CLI"  install_azure_cli
  install_if_missing wezterm "WezTerm"    install_wezterm

  if ! fzf --zsh &>/dev/null 2>&1; then
    log_info "Installing fzf from GitHub (requires --zsh support)..."
    install_fzf
    log_success "fzf installed"
  else
    log_success "fzf already installed ($(fzf --version | awk '{print $1}'))"
  fi

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

  local _theme="$HOME/.cache/oh-my-posh/themes/iterm2.omp.json"
  if [ ! -f "$_theme" ]; then
    log_info "Downloading Oh My Posh theme..."
    mkdir -p "$(dirname "$_theme")"
    curl -fsSL "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/iterm2.omp.json" \
      -o "$_theme"
    log_success "Theme downloaded"
  else
    log_success "Oh My Posh theme already present"
  fi
  unset _theme

  if fc-list | grep -qi "Maple Mono NF CN"; then
    log_success "Maple Mono NF CN already installed"
  else
    log_info "Installing Maple Mono NF CN..."
    local _maple_dir="$HOME/.local/share/fonts/MapleMono"
    mkdir -p "$_maple_dir"
    local _maple_ver
    _maple_ver=$(curl -fsSL https://api.github.com/repos/subframe7536/maple-font/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -fsSL "https://github.com/subframe7536/maple-font/releases/download/${_maple_ver}/MapleMono-NF-CN.zip" \
      -o /tmp/maple-nf-cn.zip
    unzip -q /tmp/maple-nf-cn.zip -d "$_maple_dir"
    rm /tmp/maple-nf-cn.zip
    fc-cache -f "$_maple_dir"
    unset _maple_dir _maple_ver
    log_success "Maple Mono NF CN installed"
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
    set +u
    nvm install --lts
    nvm use --lts
    set -u
    log_success "nvm + Node.js installed"
  else
    log_success "nvm already installed"
    export NVM_DIR="$HOME/.nvm"
    set +u
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    set -u
  fi

  for _pkg in "@openai/codex" "@anthropic-ai/claude-code"; do
    local _cmd
    _cmd="$(basename "$_pkg")"
    if ! command -v "$_cmd" &>/dev/null; then
      log_info "Installing $_pkg..."
      npm install -g "$_pkg"
      log_success "$_pkg installed"
    else
      log_success "$_pkg already installed"
    fi
  done
  unset _pkg _cmd

  log_success "Ubuntu/Mint setup complete"
}

setup_ubuntu
