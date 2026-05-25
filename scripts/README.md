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
| `omarchy-kitty-font-setup.sh` | Installs Kitty terminal and CodeNewRoman Nerd Font, then sets it as the system font via `omarchy-font-set` |
| `staticIP.sh` | Configures a static IP address on a Raspberry Pi via `dhcpcd.conf` |

## Notes

- `install_tools_and_zsh_plugins.sh` and `staticIP.sh` target Raspberry Pi OS (apt/dhcpcd) — not Arch
- `run-omarchy-cleaner.sh` and `omarchy-kitty-font-setup.sh` are for Omarchy (Arch-based)
- All scripts include a cross-distro compatibility prolog for `pacman`, `apt`, and `apk`
