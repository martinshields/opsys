# OPSYS 🛠️

Install script for Arch Linux (Omarchy) system setup.

## 📋 Prerequisites

- Omarchy installed (download ISO from https://learn.omacom.io/2/the-omarchy-manual/50/getting-started)
- Git and wget installed
- Internet connection
- sudo privileges

## 🚀 Installation

1. Clone this repository:

```bash
git clone https://github.com/martinshields/opsys.git
```

2. Run the setup script:

```bash
./run.sh
```

3. Reboot your system to apply changes.

## 📂 Additional Scripts

Scripts are located in `scripts/arch/`:

- `run-omarchy-cleaner.sh` - Remove bloat software
- `install_docker_tools.sh` - Install Docker and Lazydocker
- `install_deluge.sh` - Set up Deluge torrent client
- `setup_deluge_vpn.sh` - Set up Deluge with VPN
- `install_pihole.sh` - Install Pi-hole
- `setup_samba.sh` - Configure Samba file sharing
- `install_tools_and_zsh_plugins.sh` - Install tools and ZSH plugins
- `omarchy-kitty-font-setup.sh` - Configure Kitty terminal fonts

## 🖥️ VirtualBox Monitor Setting

If needed:

```bash
monitor=VGA-1,1920x1080@60.0,1920x1080,1.2
```
