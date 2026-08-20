# OPSYS

Install script for Arch Linux (Omarchy) system setup.

## Prerequisites

- Omarchy installed
- Git and wget installed
- Internet connection
- sudo privileges

## Installation

1. Clone this repository:

```bash
git clone https://github.com/martinshields/opsys.git
```

2. Run the setup script:

```bash
./run.sh
```

To install only development tools (skip desktop/media/fonts):

```bash
./run.sh --dev-only
```

3. Reboot your system to apply changes.

## Files

| File | Description |
|------|-------------|
| `run.sh` | Main setup script — installs packages, enables services, runs dotfiles setup |
| `packages.conf` | Package lists by category (system utils, dev tools, maintenance, desktop, media, fonts) and services to enable |
| `dotfiles-setup.sh` | Installs oh-my-zsh, zsh plugins, clones dotfiles via yadm, and sets default browser/terminal/font |
| `utils.sh` | Helper functions for package installation |

### dotfiles-setup.sh

Called automatically at the end of a full `run.sh` install. It:

1. Downloads vifm color theme (`palenight.vifm`) and creates `~/adata/temp`
2. Installs [oh-my-zsh](https://ohmyz.sh/) (unattended, no shell change yet)
3. Clones `zsh-autosuggestions` and `zsh-completions` plugins into oh-my-zsh custom plugins
4. Backs up any existing Neovim config (`~/.config/nvim`) before overwriting
5. Clones dotfiles from [martinshields/dotfiles](https://github.com/martinshields/dotfiles) via `yadm`, backing up any conflicting files to a timestamped directory
6. Copies `aliasmartin.zsh` and `functions.zsh` into `~/.oh-my-zsh/custom/`
7. Changes the default shell to Zsh (`chsh -s /usr/bin/zsh`)
8. Sets Brave as the default browser, Kitty as the default terminal, and "CodeNewRoman Nerd Font" as the system font
9. Reboots after a 10-second countdown

> **Note:** The script will prompt before removing an existing oh-my-zsh or Neovim config directory.

## Scripts (`scripts/arch/`)

| Script | Description |
|--------|-------------|
| `run-omarchy-cleaner.sh` | Remove bloat software |
| `install_tools_and_zsh_plugins.sh` | Install tools and ZSH plugins |
| `staticIP.sh` | Set a static IP address |
