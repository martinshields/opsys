# Opsys Scripts — Arch Linux 🛠️

Scripts for Arch Linux (Omarchy) system setup and configuration.

## 📂 Structure

```
scripts/
 └── arch/   ← Arch Linux scripts
```

---

## 🧩 Usage

1. **Make sure scripts are executable**:
   ```bash
   chmod +x *.sh
   ```

2. **Run a script** with `sudo`:
   ```bash
   sudo ./install_pihole.sh
   ```

---

## ⚙️ Script Overview

| Script | Description |
|:-------|:------------|
| `install_deluge.sh` | Installs Deluge torrent client with Docker support |
| `install_docker_tools.sh` | Installs Docker, Docker Compose, and Lazydocker |
| `install_pihole.sh` | Installs Pi-hole network ad blocker |
| `install_tools_and_zsh_plugins.sh` | Installs Zsh, Git, and common CLI tools |
| `omarchy-kitty-font-setup.sh` | Installs Kitty terminal and Nerd Fonts |
| `run-omarchy-cleaner.sh` | Cleans up bloat software |
| `setup_deluge_vpn.sh` | Configures Deluge + VPN in Docker |
| `setup_samba.sh` | Installs and configures Samba shares |
| `setup_usb_and_folder.sh` | Mounts and configures USB storage |

---

## ⚠️ Notes

- All scripts assume `sudo` is available
- Scripts use `pacman` for package management

---

© Martin Shields — Opsys Project
