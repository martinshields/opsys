#!/usr/bin/env bash
# Cross-distro compatibility prolog (auto-inserted)
# Works on Arch Linux (pacman) and Debian-based (apt) like Raspberry Pi OS.
set -euo pipefail
IFS=$'\n\t'

detect_pkg_mgr() {
    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
    elif command -v apt-get >/dev/null 2>&1 || command -v apt >/dev/null 2>&1; then
        PKG_MGR="apt"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MGR="apk"
    else
        PKG_MGR="unknown"
    fi
}

pkg_install() {
    detect_pkg_mgr
    case "$PKG_MGR" in
        pacman) pkg_install "$@" ;;
        apt) pkg_install && -y "$@" ;;
        apk) sudo apk add "$@" ;;
        *) echo "No known package manager found; please install: $*" >&2; return 1 ;;
    esac
}

# wrapper for systemctl where not available
maybe_systemctl() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl "$@"
    else
        echo "systemctl not available on this system. $*" >&2
        return 1
    fi
}

# wrapper for architecture
ARCH=$(uname -m)
# normalize common architecture names
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7*|armv6*) ARCH="armv7" ;;
esac

# End of prolog

# Omarchy: Install Kitty + Set CodeNewRoman Nerd Font
# Run with: bash omarchy-kitty-font-setup.sh

echo "=== Omarchy Kitty + CodeNewRoman Nerd Font Setup ==="
echo "This script will install Kitty, the font, and configure everything."
echo "Press Enter to continue or Ctrl+C to abort."

read -p ""

# Step 1: Install packages
echo "Step 1: Installing kitty and otf-codenewroman-nerd..."
read -p "Run 'pkg_install kitty otf-codenewroman-nerd && fc-cache -fv'? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # omarchy-install-terminal kitty
    pkg_install kitty otf-codenewroman-nerd
    fc-cache -fv
    echo "✓ Installed!"
else
    echo "Skipped. Install manually if needed."
fi

# Step 2: Create Kitty config
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
echo "Step 2: Setting up Kitty config with CodeNewRoman Nerd Font..."
if [[ ! -f $KITTY_CONF ]]; then
    mkdir -p "$(dirname "$KITTY_CONF")"
fi
cat > "$KITTY_CONF" << EOF
font_family      CodeNewRoman Nerd Font Mono
font_size        14

background_opacity 0.95
background       #0a0a0a
foreground       #ffffff
cursor           #ffffff
selection_background #0066cc
url_color        #0087bd

allow_remote_control yes
confirm_os_window_close 0   
EOF
echo "✓ Kitty config created/updated."

# Step 3: Set as default terminal
echo "Step 3: Adding Kitty as default terminal alias..."
if ! grep -q "alias term=kitty" "$HOME/.zshrc" 2>/dev/null; then
    echo 'alias term=kitty' >> "$HOME/.zshrc"
    echo 'export TERMINAL=kitty' >> "$HOME/.zshrc"
    echo "✓ Added to ~/.zshrc. Source it with 'source ~/.zshrc'."
else
    echo "Already configured."
fi

# read -p "Edit Hyprland.conf for global keybind? (Manual: change 'alacritty' to 'kitty' in bind= line) (y/n): " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     echo "Open ~/.config/hypr/hyprland.conf and update: bind = SUPER, Return, exec, kitty"
#     echo "Then run 'hyprctl reload'."
# fi
#
# Step 4: Set font with omarchy-font-set
echo "Step 4: Setting system font..."
read -p "Run 'omarchy-font-set \"CodeNewRoman Nerd Font\"'? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    omarchy-font-set "CodeNewRoman Nerd Font"
    echo "✓ Font set! Restart session or run 'hyprctl reload'."
else
    echo "Skipped. Run manually."
fi
#
# echo " Install the Kitty terminal and make it default using the command: omarchy-install-terminal kitty"
# read -p "Would you like to proceed with running this command? (y/n): " answer
#
# if [[ "$answer" =~ ^[Yy]$ ]]; then
#     echo "Running the command..."
#     omarchy-install-terminal kitty
#     if [ $? -eq 0 ]; then
#         echo "Command executed successfully!"
#     else
#         echo "Error: The command failed to execute."
#     fi
# else
#     echo "Operation cancelled by user."
# fi
# Test
echo ""
echo "=== Setup Complete! ==="
echo "Test: Run 'kitty' and check icons with 'echo -e \"\\uf015 \\ue0b0\"'."
echo "If icons are broken, verify font: fc-list | grep CodeNewRoman"
