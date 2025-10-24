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

# Script to install specified tools and zsh plugins via APT on Raspberry Pi 4 (Raspberry Pi OS)
# Tools: htop, lazygit, neofetch, nerdfetch, zip, unzip, wget, curl, lsd, speedtest-cli, vim, nano, bat, vifm, zsh, neovim, git, ohmyzsh
# Zsh Plugins: zsh-autosuggestions, zsh-syntax-highlighting, fzf, git, z, autojump, thefuck, command-not-found, docker.io, colored-man-pages
# Note: Some tools (lazygit, lsd, bat, nerdfetch, ohmyzsh) and plugins (zsh-autosuggestions, zsh-syntax-highlighting, fzf, thefuck) need extra steps.

set -e  # Exit on any error

echo "Updating package list..."
sudo apt update

echo "Installing available APT packages..."
pkg_install -y \
    htop \
    neofetch \
    zip \
    unzip \
    wget \
    curl \
    speedtest-cli \
    vim \
    nano \
    vifm \
    zsh \
    neovim \
    git \
    fzf \
    autojump \
    command-not-found \
    python3-pip

# Install lazygit (not in default repos, using GitHub release for ARM64)
echo "Installing lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
wget -O /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_arm64.tar.gz"
tar -xzf /tmp/lazygit.tar.gz -C /tmp
sudo mv /tmp/lazygit /usr/local/bin/
rm /tmp/lazygit.tar.gz
echo "lazygit installed."

# Install lsd (not in default repos, using GitHub release for ARM64)
echo "Installing lsd..."
LSD_VERSION=$(curl -s "https://api.github.com/repos/Peltoche/lsd/releases/latest" | grep -Po '"tag Observations": "\K[^"]*')
wget -O /tmp/lsd.deb "https://github.com/Peltoche/lsd/releases/latest/download/lsd_${LSD_VERSION}_arm64.deb"
sudo dpkg -i /tmp/lsd.deb
rm /tmp/lsd.deb
echo "lsd installed."

# Install bat (not in default repos, using GitHub release for ARM64)
echo "Installing bat..."
BAT_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
wget -O /tmp/bat.deb "https://github.com/sharkdp/bat/releases/latest/download/bat_${BAT_VERSION}_arm64.deb"
sudo dpkg -i /tmp/bat.deb
rm /tmp/bat.deb
echo "bat installed."

# Install nerdfetch (not in default repos, manual install from GitHub)
echo "Installing nerdfetch..."
sudo wget -O /usr/local/bin/nerdfetch https://raw.githubusercontent.com/ThatOneCalculator/NerdFetch/main/nerdfetch
sudo chmod +x /usr/local/bin/nerdfetch
echo "nerdfetch installed."

# Install ohmyzsh
echo "Installing ohmyzsh..."
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" --unattended
echo "ohmyzsh installed."

# Install zsh plugins
echo "Installing zsh plugins..."

# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# thefuck (requires pip)
pip3 install thefuck

# Backup existing .zshrc
if [ -f ~/.zshrc ]; then
    cp ~/.zshrc ~/.zshrc.bak
    echo "Backed up existing ~/.zshrc to ~/.zshrc.bak"
fi

# Update .zshrc to include plugins
echo "Configuring ~/.zshrc with plugins..."
cat <<EOL > ~/.zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="pygmalion"
plugins=(
    git
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
    autojump
    thefuck
    command-not-found
    docker.io
    colored-man-pages
)
source \$ZSH/oh-my-zsh.sh
eval \$(thefuck --alias)
. /usr/share/autojump/autojump.sh
EOL

echo "Reloading zsh configuration..."
source ~/.zshrc || true

echo "Installation complete! All tools and zsh plugins installed."
echo "Run 'zsh' to start using the new configuration, or set zsh as default shell with 'chsh -s \$(which zsh)'."
echo "Note: If plugins don't work, check ~/.zshrc and ensure all dependencies are installed."
