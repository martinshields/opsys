#!/bin/bash
#Make sure you install Omarchy bare mode frist "wget -qO- https://omarchy.org/install-bare | bash"
#and your ~/.ssh folder
 

# Print the logo
print_logo() {
    cat << "EOF"
 ██████  ██████  ███████ ██    ██ ███████ 
██    ██ ██   ██ ██       ██  ██  ██      
██    ██ ██████  ███████   ████   ███████ 
██    ██ ██           ██    ██         ██ 
 ██████  ██      ███████    ██    ███████ 
                                          
                                         :Install my default system 
EOF
}

# Parse command line arguments
DEV_ONLY=false
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dev-only) DEV_ONLY=true; shift ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
done

# Clear screen and show logo
clear
print_logo

# Exit on any error
set -e

# Source utility functions
source utils.sh

# Source the package list
if [ ! -f "packages.conf" ]; then
  echo "Error: packages.conf not found!"
  exit 1
fi

source packages.conf

if [[ "$DEV_ONLY" == true ]]; then
  echo "Starting development-only setup..."
else
  echo "Starting full system setup..."
fi

# Update the system first
echo "Updating system..."
sudo pacman -Syu 
# sudo pacman -Syu --noconfirm --ignore uwsm

# Install yay AUR helper if not present
if ! command -v yay &> /dev/null; then
  echo "Installing yay AUR helper..."
  sudo pacman -S --needed git base-devel --noconfirm
  if [[ ! -d "yay" ]]; then
    echo "Cloning yay repository..."
  else
    echo "yay directory already exists, removing it..."
    rm -rf yay
  fi

  git clone https://aur.archlinux.org/yay.git

  cd yay
  echo "building yay.... yaaaaayyyyy"
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  echo "yay is already installed"
fi

# Install packages by category
if [[ "$DEV_ONLY" == true ]]; then
  # Only install essential development packages
  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"
  
  echo "Installing development tools..."
  install_packages "${DEV_TOOLS[@]}"
else
  # Install all packages
  echo "Installing system utilities..."
  install_packages "${SYSTEM_UTILS[@]}"
  
  echo "Installing development tools..."
  install_packages "${DEV_TOOLS[@]}"
  
  echo "Installing system maintenance tools..."
  install_packages "${MAINTENANCE[@]}"
  
  echo "Installing desktop environment..."
  install_packages "${DESKTOP[@]}"
  
  echo "Installing desktop environment..."
  install_packages "${OFFICE[@]}"
  
  echo "Installing media packages..."
  install_packages "${MEDIA[@]}"
  
  echo "Installing fonts..."
  install_packages "${FONTS[@]}"
  
  # Enable services
  echo "Configuring services..."
  for service in "${SERVICES[@]}"; do
    if ! systemctl is-enabled "$service" &> /dev/null; then
      echo "Enabling $service..."
      sudo systemctl enable "$service"
    else
      echo "$service is already enabled"
    fi
  done

# # Install oh-my-zsh
#
# echo "Installing oh-my-zsh"
# RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
#
# # Set ZSH_CUSTOM if it's not already set
# ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH:-$HOME/.oh-my-zsh}/custom}"
#
# # Install zsh plugins
# echo "Installing zsh plugins"
# git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
# git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

 # Install yadm dotfiles
  echo "Installing dotfiles-setup"
  . dotfiles-setup.sh
  
fi

echo "Setup complete! You may want to reboot your system."
