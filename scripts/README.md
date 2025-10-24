# Opsys Scripts — Arch & Raspberry Pi Versions

These scripts have been split into two sets for convenience and portability.

## 📂 Structure

```
scripts/
 ├── rpi/    ← Raspberry Pi OS (Debian-based) versions
 └── arch/   ← Arch Linux versions
```


---

## 🧩 Usage

1. **Make sure scripts are executable** (already done here):
   ```bash
   chmod +x *.sh
   ```

2. **Run a script** as root or with `sudo`:
   ```bash
   sudo ./install_pihole_rpi.sh
   ```
   or on Arch:
   ```bash
   sudo ./install_pihole_arch.sh
   ```

3. **pkg_install wrapper**
   - Automatically detects package manager (`pacman`, `apt`, `apk`).
   - Non-interactive install (`--noconfirm`, `-y`).
   - Can be extended with new mappings if needed.

---

## ⚙️ Script Overview

| Script | Description | Notes |
|:--------|:-------------|:------|
| `install_deluge_*` | Installs Deluge torrent client with Docker support. | RPi uses `docker.io`; Arch uses `docker`. |
| `install_pihole_*` | Installs Pi-hole network ad blocker. | Works natively on RPi. |
| `install_tools_and_zsh_plugins_*` | Installs Zsh, Git, and common CLI tools. | Compatible on both systems. |
| `omarchy-kitty-font-setup_*` | Installs Kitty terminal and Nerd Fonts. | For Omarchy only. |
| `run-omarchy-cleaner_*` | Cleans up temporary files. | For Omarchy only. |
| `setup_deluge_vpn_*` | Configures Deluge + VPN in Docker. | RPi version skips lazydocker. |
| `setup_samba_*` | Installs and configures Samba shares. | Package names differ. |
| `setup_usb_and_folder_*` | Mounts and configures USB storage. | Universal. |
| `staticIP-rpi_*` | Configures static IP. | Universal. |
| `docker_install_tools_*` | installs Docker,Docker compose,lazydocker | Universal. |

---

## ⚠️ Notes

- Raspberry Pi OS lacks `lazydocker` and some Arch packages. Those were skipped safely.
- Font packages differ; Debian uses `fonts-*` prefix.
- All scripts assume `sudo` is available.
- To extend for new systems, modify `pkg_install` in the prolog.

---

© Martin Shields — Opsys Project
