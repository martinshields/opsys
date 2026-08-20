# Opsys Scripts — Arch Linux

Additional scripts for system setup and configuration.

## Structure

```
scripts/
 └── arch/   ← Arch Linux / Raspberry Pi scripts
```

## Usage

Make scripts executable before running:

```bash
chmod +x scripts/arch/*.sh
```

## Script Overview

| Script | Description |
|--------|-------------|
| `run-omarchy-cleaner.sh` | Downloads and runs [omarchy-cleaner](https://github.com/maxart/omarchy-cleaner) to remove bloat software |
| `install_tools_and_zsh_plugins.sh` | Installs CLI tools (htop, lazygit, bat, neovim, etc.) and oh-my-zsh with plugins — targets apt-based systems (Raspberry Pi OS) |
| `staticIP.sh` | Configures a static IP address on a Raspberry Pi via `dhcpcd.conf` |

## Notes

- `install_tools_and_zsh_plugins.sh` and `staticIP.sh` target Raspberry Pi OS (apt/dhcpcd) — not Arch
- `run-omarchy-cleaner.sh` is for Omarchy (Arch-based)
- All scripts include a cross-distro compatibility prolog for `pacman`, `apt`, and `apk`
- The default browser (Brave), terminal (Kitty), and font (CodeNewRoman Nerd Font) are now set directly in `dotfiles-setup.sh` via `omarchy-default-browser`, `omarchy-default-terminal`, and `omarchy-font-set`
