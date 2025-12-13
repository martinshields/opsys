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
   sudo ./install_pihole_arch.sh
   ```

---

## ⚙️ Script Overview

| Script | Description |
|:-------|:------------|
| `install_deluge_arch_arch.sh` | Installs Deluge torrent client with Docker support |
| `install_docker_tools_arch.sh` | Installs Docker, Docker Compose, and Lazydocker |
| `install_pihole_arch.sh` | Installs Pi-hole network ad blocker |
| `install_tools_and_zsh_plugins_arch.sh` | Installs Zsh, Git, and common CLI tools |
| `omarchy-kitty-font-setup_arch.sh` | Installs Kitty terminal and Nerd Fonts |
| `run-omarchy-cleaner_arch.sh` | Cleans up bloat software |
| `setup_deluge_vpn_arch.sh` | Configures Deluge + VPN in Docker |
| `setup_samba_arch.sh` | Installs and configures Samba shares |
| `setup_usb_and_folder_arch.sh` | Mounts and configures USB storage |

---

## ⚠️ Notes

- All scripts assume `sudo` is available
- Scripts use `pacman` for package management

---

© Martin Shields — Opsys Project
