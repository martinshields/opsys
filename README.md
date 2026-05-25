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
| `packages.conf` | Package lists by category (system utils, dev tools, desktop, media, fonts) |
| `dotfiles-setup.sh` | Installs oh-my-zsh, zsh plugins, and clones dotfiles via yadm |
| `utils.sh` | Helper functions for package installation |

## Scripts (`scripts/arch/`)

| Script | Description |
|--------|-------------|
| `run-omarchy-cleaner.sh` | Remove bloat software |
| `install_tools_and_zsh_plugins.sh` | Install tools and ZSH plugins |
| `omarchy-kitty-font-setup.sh` | Configure Kitty terminal fonts |
| `staticIP.sh` | Set a static IP address |
