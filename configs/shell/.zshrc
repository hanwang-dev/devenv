# User-local binaries
export PATH="$HOME/.local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Go
export GOPATH="$HOME/go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"

# nvm (Node.js)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# GitHub CLI completion
if command -v gh &>/dev/null; then
  eval "$(gh completion -s zsh)"
fi

# Azure CLI completion
if [ -f "$HOME/.azure/az.completion" ]; then
  source "$HOME/.azure/az.completion"
fi

# Editor
export EDITOR="code --wait"

# Aliases — git
alias gs='git status -sb'
alias gl='git lg'
alias gp='git push'
alias gpl='git pull'
alias gc='git commit'

# Aliases — navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lah'

# Aliases — Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'

# Aliases — Go
alias gor='go run .'
alias got='go test ./...'
alias gob='go build ./...'


# Oh My Posh — p10k-style prompt theme
command -v oh-my-posh &>/dev/null && eval "$(oh-my-posh init zsh --config "${POSH_THEMES_PATH:-$HOME/.cache/oh-my-posh/themes}/iterm2.omp.json")"

# zsh plugins (autosuggestions + syntax highlighting)
_brew="$(brew --prefix 2>/dev/null)"
for _plugin in zsh-autosuggestions/zsh-autosuggestions.zsh zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if   [ -f "$_brew/share/$_plugin" ]; then source "$_brew/share/$_plugin"
  elif [ -f "$HOME/.zsh/$_plugin" ];   then source "$HOME/.zsh/$_plugin"
  fi
done
unset _brew _plugin

# zoxide — frecency-based directory jumping (z <dir>, zi for interactive fzf picker)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# fzf — fuzzy finder: Ctrl+R history · Ctrl+T files · Alt+C cd into subdir
command -v fzf &>/dev/null && eval "$(fzf --zsh)"
