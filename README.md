# mac-bootstrap

Idempotent macOS setup script. Run it once on a fresh Mac, or run it repeatedly - it'll only do what's needed.

## Quick Start

```bash
git clone https://github.com/rnxj/mac-bootstrap.git
cd mac-bootstrap
./bootstrap.sh
```

After running, restart your terminal and run `p10k configure` to set up your prompt theme.

## What It Does

### Core Tools
- **Xcode Command Line Tools** - Required for git, compilers, etc.
- **Homebrew** - Package manager for macOS
- **GitHub CLI (`gh`)** - GitHub from the command line
- **mise** - Runtime version manager (Node.js, Go, etc.)

### GitHub Setup
- **SSH key generation** - Ed25519 key with macOS Keychain integration
- **GitHub CLI authentication** - Browser-based OAuth flow
- **Automatic key upload** - Adds SSH key to your GitHub account

### Shell Setup (Zsh)
- **Zinit** - Fast plugin manager
- **Powerlevel10k** - Beautiful, fast prompt theme
- **Core plugins:**
  - `zsh-syntax-highlighting` - Command syntax colors
  - `zsh-completions` - Additional completions
  - `zsh-autosuggestions` - Fish-like suggestions
- **fzf** - Fuzzy finder for files and history
- **fzf-tab** - Fuzzy completion for tab
- **zoxide** - Smarter `cd` that learns your habits
- **Oh-My-Zsh snippets** - git, sudo, aws, kubectl aliases

### Terminal
- **Ghostty** - Fast, native terminal emulator
- **JetBrains Mono Nerd Font** - Programming font with icons
- **Catppuccin Mocha** - Easy-on-the-eyes color theme

### Apps
- Google Chrome
- Claude
- Zed (editor)
- Ghostty (terminal)

### Language Runtimes
- Node.js (latest)
- Go (latest)

## Features

- **100% Idempotent** - Safe to run multiple times
- **Smart config management** - Detects if you've modified configs and asks before overwriting
- **Automatic backups** - Backs up existing configs before replacing
- **GitHub SSH setup** - Generates key, authenticates CLI, uploads to GitHub
- **Hush login** - No more "Last login" message

## File Structure

```
mac-bootstrap/
├── bootstrap.sh    # Main setup script
├── Brewfile        # Homebrew packages
└── README.md
```

## Customization

### Adding Homebrew packages

Edit `Brewfile`:

```ruby
brew "ripgrep"
cask "spotify"
```

### Adding Zsh config

The generated `~/.zshrc` has a `USER CONFIG` section at the bottom. Add your customizations there - they'll be preserved if you re-run bootstrap and choose not to overwrite.

### Changing language runtimes

Edit the mise section in `bootstrap.sh`:

```bash
mise use --global node@20 python@3.12 go@latest
```

## What Gets Created

| File | Purpose |
|------|---------|
| `~/.zshrc` | Zsh configuration |
| `~/.p10k.zsh` | Powerlevel10k theme config (after running `p10k configure`) |
| `~/.config/ghostty/config` | Ghostty terminal config |
| `~/.hushlogin` | Disables "Last login" message |
| `~/.local/share/zinit/` | Zinit plugins |
| `~/.ssh/id_ed25519` | SSH private key (if GitHub setup enabled) |
| `~/.ssh/config` | SSH config with GitHub host settings |

## Updating

```bash
cd mac-bootstrap
git pull
./bootstrap.sh
```

The script will detect changes and prompt you to update configs if needed.

## Troubleshooting

### Fonts look weird in terminal
Make sure to select "JetBrainsMono Nerd Font" in your terminal settings, or run `p10k configure` and select "Yes" when asked about installing fonts.

### Ghostty theme not found
Make sure you're running Ghostty 1.2.0+. The theme name is `Catppuccin Mocha` (with space, title case).

### `ghostty` command not found
Restart your terminal or run `exec zsh`. The PATH is configured in `.zshrc`.

### Zsh plugins not loading
Run `exec zsh` to reload, or check if Zinit installed correctly at `~/.local/share/zinit/`.

### GitHub SSH not working
Test your connection with `ssh -T git@github.com`. If it fails:
- Run `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` to add key to agent
- Check if key is on GitHub: `gh ssh-key list`
- Re-run bootstrap and select "y" for GitHub setup

### GitHub CLI not authenticated
Run `gh auth login` and follow the prompts, or re-run bootstrap.

## Credits

Shell setup inspired by [Dreams of Autonomy](https://www.youtube.com/watch?v=ud7YxC33Z3w).
