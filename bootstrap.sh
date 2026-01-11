#!/usr/bin/env bash
set -euo pipefail

echo "🚀 macOS bootstrap (idempotent, mise-based)"

########################################
# 1. Xcode Command Line Tools
########################################
if ! xcode-select -p &>/dev/null; then
  echo "📦 Installing Xcode Command Line Tools..."
  xcode-select --install || true
  until xcode-select -p &>/dev/null; do sleep 5; done
fi

########################################
# 2. Homebrew (arch + PATH safe)
########################################
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

########################################
# 3. Brewfile
########################################
echo "📦 Installing Brewfile packages..."
brew bundle --quiet

########################################
# 4. Hush Login (disable "Last login" message)
########################################
if [[ ! -f "$HOME/.hushlogin" ]]; then
  echo "🤫 Creating .hushlogin..."
  touch "$HOME/.hushlogin"
else
  echo "✓ .hushlogin already exists"
fi

########################################
# 5. Zinit (Zsh Plugin Manager)
########################################
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  echo "🔌 Installing Zinit..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  chmod g-rwX "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
else
  echo "✓ Zinit already installed"
fi

########################################
# 6. Zsh Configuration
########################################
ZSHRC="$HOME/.zshrc"
ZSHRC_MARKER="# === BOOTSTRAP MANAGED ==="

generate_zshrc_content() {
  cat << 'EOF'
# === BOOTSTRAP MANAGED ===
# This file is managed by bootstrap.sh
# Manual changes below the "USER CONFIG" section will be preserved on re-run

########################################
# Path Additions
########################################
# Ghostty CLI
if [[ -d "/Applications/Ghostty.app/Contents/MacOS" ]]; then
  export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"
fi

########################################
# Zinit Plugin Manager
########################################
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
source "$ZINIT_HOME/zinit.zsh"

########################################
# Powerlevel10k Theme
########################################
# Enable Powerlevel10k instant prompt (should stay close to top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

zinit ice depth=1
zinit light romkatv/powerlevel10k

# Load p10k config if it exists
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

########################################
# Core Plugins (The Big Three)
########################################
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

########################################
# fzf-tab (must load after completions, before compinit)
########################################
zinit light Aloxaf/fzf-tab

########################################
# Oh-My-Zsh Snippets
########################################
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::command-not-found

########################################
# Completion System
########################################
autoload -Uz compinit
# Only regenerate .zcompdump once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

zinit cdreplay -q

########################################
# Completion Styling
########################################
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

########################################
# History Configuration
########################################
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks

########################################
# Keybindings
########################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

########################################
# Shell Integrations
########################################
# fzf
eval "$(fzf --zsh)"

# zoxide (modern cd replacement)
eval "$(zoxide init --cmd cd zsh)"

# mise (runtime manager)
eval "$(mise activate zsh)"

########################################
# Aliases
########################################
alias ls='ls --color'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

########################################
# === USER CONFIG ===
# Add your custom configuration below this line
########################################
EOF
}

write_zshrc() {
  echo "🐚 Configuring Zsh..."
  # Backup existing .zshrc if it exists and isn't ours
  if [[ -f "$ZSHRC" ]] && ! grep -q "$ZSHRC_MARKER" "$ZSHRC"; then
    echo "📋 Backing up existing .zshrc to .zshrc.pre-bootstrap"
    cp "$ZSHRC" "$HOME/.zshrc.pre-bootstrap"
  fi
  generate_zshrc_content > "$ZSHRC"
  echo "✓ Zsh configured"
}

# Check if .zshrc needs to be created or updated
if [[ ! -f "$ZSHRC" ]]; then
  write_zshrc
elif ! grep -q "$ZSHRC_MARKER" "$ZSHRC"; then
  write_zshrc
elif [[ "$(generate_zshrc_content)" == "$(cat "$ZSHRC")" ]]; then
  echo "✓ Zsh already configured by bootstrap"
else
  echo "⚠️  ~/.zshrc differs from bootstrap template"
  read -rp "   Overwrite with bootstrap config? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    cp "$ZSHRC" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    write_zshrc
  else
    echo "   Skipping .zshrc update"
  fi
fi

########################################
# 7. Ghostty Configuration
########################################
GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
GHOSTTY_CONFIG="$GHOSTTY_CONFIG_DIR/config"
GHOSTTY_MARKER="# === BOOTSTRAP MANAGED ==="

generate_ghostty_content() {
  cat << 'EOF'
# === BOOTSTRAP MANAGED ===
# Ghostty terminal configuration

########################################
# Font Configuration
########################################
font-family = JetBrainsMono Nerd Font
font-size = 14
font-thicken = true

########################################
# Window Configuration
########################################
window-padding-x = 10
window-padding-y = 10
window-decoration = true
macos-titlebar-style = tabs
window-save-state = always

########################################
# Cursor
########################################
cursor-style = block
cursor-style-blink = false
shell-integration-features = cursor

########################################
# Theme
########################################
theme = Catppuccin Mocha

########################################
# Keybindings
########################################
keybind = super+t=new_tab
keybind = super+w=close_surface
keybind = super+shift+left=previous_tab
keybind = super+shift+right=next_tab
keybind = super+equal=increase_font_size:1
keybind = super+minus=decrease_font_size:1
keybind = super+zero=reset_font_size

########################################
# Misc
########################################
copy-on-select = clipboard
confirm-close-surface = false
mouse-hide-while-typing = true
EOF
}

write_ghostty() {
  echo "👻 Configuring Ghostty..."
  mkdir -p "$GHOSTTY_CONFIG_DIR"
  generate_ghostty_content > "$GHOSTTY_CONFIG"
  echo "✓ Ghostty configured"
}

# Check if Ghostty config needs to be created or updated
if [[ ! -f "$GHOSTTY_CONFIG" ]]; then
  write_ghostty
elif ! grep -q "$GHOSTTY_MARKER" "$GHOSTTY_CONFIG"; then
  write_ghostty
elif [[ "$(generate_ghostty_content)" == "$(cat "$GHOSTTY_CONFIG")" ]]; then
  echo "✓ Ghostty already configured by bootstrap"
else
  echo "⚠️  ~/.config/ghostty/config differs from bootstrap template"
  read -rp "   Overwrite with bootstrap config? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    cp "$GHOSTTY_CONFIG" "$GHOSTTY_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
    write_ghostty
  else
    echo "   Skipping Ghostty config update"
  fi
fi

########################################
# 8. GitHub SSH Key Setup
########################################
SSH_KEY="$HOME/.ssh/id_ed25519"

setup_github_ssh() {
  echo "🔑 Setting up GitHub SSH key..."

  # Create .ssh directory if it doesn't exist
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Generate SSH key if it doesn't exist
  if [[ ! -f "$SSH_KEY" ]]; then
    read -rp "   Enter your GitHub email: " github_email
    ssh-keygen -t ed25519 -C "$github_email" -f "$SSH_KEY" -N ""
    echo "   ✓ SSH key generated"
  else
    echo "   ✓ SSH key already exists"
  fi

  # Start ssh-agent and add key
  eval "$(ssh-agent -s)" >/dev/null

  # Create/update SSH config for macOS keychain integration
  SSH_CONFIG="$HOME/.ssh/config"
  if [[ ! -f "$SSH_CONFIG" ]] || ! grep -q "AddKeysToAgent yes" "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" << 'EOF'
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    echo "   ✓ SSH config updated"
  fi

  # Add key to ssh-agent and keychain
  ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

  # Check if gh is authenticated
  if ! gh auth status &>/dev/null; then
    echo "   📋 Authenticating with GitHub CLI..."
    gh auth login -p ssh -h github.com -w
  else
    echo "   ✓ GitHub CLI already authenticated"
  fi

  # Check if SSH key is already added to GitHub
  KEY_FINGERPRINT=$(ssh-keygen -lf "$SSH_KEY.pub" | awk '{print $2}')
  if gh ssh-key list 2>/dev/null | grep -q "$KEY_FINGERPRINT"; then
    echo "   ✓ SSH key already added to GitHub"
  else
    # Add SSH key to GitHub
    KEY_TITLE="$(hostname)-$(date +%Y%m%d)"
    gh ssh-key add "$SSH_KEY.pub" -t "$KEY_TITLE"
    echo "   ✓ SSH key added to GitHub as '$KEY_TITLE'"
  fi

  # Test SSH connection
  echo "   Testing GitHub SSH connection..."
  if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "   ✓ GitHub SSH connection working"
  fi
}

if [[ ! -f "$SSH_KEY" ]]; then
  read -rp "🔑 Set up GitHub SSH key? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    setup_github_ssh
  else
    echo "   Skipping GitHub SSH setup"
  fi
elif ! gh auth status &>/dev/null; then
  read -rp "🔑 SSH key exists but GitHub CLI not authenticated. Authenticate? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    setup_github_ssh
  else
    echo "   Skipping GitHub authentication"
  fi
else
  echo "✓ GitHub SSH already configured"
fi

########################################
# 9. mise activation
########################################
# Activate mise for THIS script (bash)
eval "$(mise activate bash)"

########################################
# 10. Install language runtimes
########################################
echo "⚙️ Installing language runtimes via mise..."
mise install --quiet
mise use --global node@latest go@latest

# IMPORTANT: refresh shims + PATH
mise reshim
eval "$(mise activate bash)"

########################################
# 11. Verification
########################################
echo ""
echo "✅ Installed versions:"
command -v node >/dev/null && echo "  Node: $(node -v)" || echo "  ❌ node not found"
command -v go >/dev/null && echo "  Go: $(go version | awk '{print $3}')" || echo "  ❌ go not found"
command -v fzf >/dev/null && echo "  fzf: $(fzf --version | awk '{print $1}')" || echo "  ❌ fzf not found"
command -v zoxide >/dev/null && echo "  zoxide: $(zoxide --version | awk '{print $2}')" || echo "  ❌ zoxide not found"

echo ""
echo "📁 Configuration files:"
[[ -f "$ZSHRC" ]] && echo "  ✓ ~/.zshrc" || echo "  ❌ ~/.zshrc missing"
[[ -f "$GHOSTTY_CONFIG" ]] && echo "  ✓ ~/.config/ghostty/config" || echo "  ❌ Ghostty config missing"
[[ -d "$ZINIT_HOME" ]] && echo "  ✓ Zinit installed" || echo "  ❌ Zinit missing"
[[ -f "$SSH_KEY" ]] && echo "  ✓ SSH key configured" || echo "  ⚠️  SSH key not set up"
gh auth status &>/dev/null && echo "  ✓ GitHub CLI authenticated" || echo "  ⚠️  GitHub CLI not authenticated"

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "👉 Next steps:"
echo "   1. Restart your terminal (or run: exec zsh)"
echo "   2. Run 'p10k configure' to set up your prompt theme"
echo "   3. Open Ghostty to use your new terminal"
