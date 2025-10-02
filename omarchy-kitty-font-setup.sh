#!/bin/bash

# Omarchy: Install Kitty + Set CodeNewRoman Nerd Font
# Run with: bash omarchy-kitty-font-setup.sh

echo "=== Omarchy Kitty + CodeNewRoman Nerd Font Setup ==="
echo "This script will install Kitty, the font, and configure everything."
echo "Press Enter to continue or Ctrl+C to abort."

read -p ""

# Step 1: Install packages
echo "Step 1: Installing kitty and otf-codenewroman-nerd..."
read -p "Run 'omarchy-install-terminal kitty && pacman -Syu otf-codenewroman-nerd && fc-cache -fv'? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    omarchy-install-terminal kitty
    sudo pacman -Syu --noconfirm otf-codenewroman-nerd
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
EOF
echo "✓ Kitty config created/updated."

# # Step 3: Set as default terminal
# echo "Step 3: Adding Kitty as default terminal alias..."
# if ! grep -q "alias term=kitty" "$HOME/.zshrc" 2>/dev/null; then
#     echo 'alias term=kitty' >> "$HOME/.zshrc"
#     echo 'export TERMINAL=kitty' >> "$HOME/.zshrc"
#     echo "✓ Added to ~/.zshrc. Source it with 'source ~/.zshrc'."
# else
#     echo "Already configured."
# fi
#
# read -p "Edit Hyprland.conf for global keybind? (Manual: change 'alacritty' to 'kitty' in bind= line) (y/n): " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#     echo "Open ~/.config/hypr/hyprland.conf and update: bind = SUPER, Return, exec, kitty"
#     echo "Then run 'hyprctl reload'."
# fi

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

# Test
echo ""
echo "=== Setup Complete! ==="
echo "Test: Run 'kitty' and check icons with 'echo -e \"\\uf015 \\ue0b0\"'."
echo "If icons are broken, verify font: fc-list | grep CodeNewRoman"
