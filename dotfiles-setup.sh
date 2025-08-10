#!/bin/bash

REPO_URL="https://github.com/martinshields/dotfiles.git"

# Check if yadm is installed
is_yadm_installed() {
  command -v yadm >/dev/null 2>&1
}

if ! is_yadm_installed; then
  echo "Error: yadm is not installed. Please install yadm first."
  exit 1
fi

# Install oh-my-zsh
echo "Installing oh-my-zsh..."
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended || {
  echo "Error: Failed to install oh-my-zsh."
  exit 1
}

# Remove existing Neovim configuration
echo "Removing old Neovim configuration..."
rm -rf ~/.config/nvim || {
  echo "Error: Failed to remove ~/.config/nvim."
  exit 1
}

# Clone dotfiles with yadm, forcing overwrite of existing files
echo "Cloning dotfiles (overwriting existing files)..."
if yadm status >/dev/null 2>&1; then
  echo "Warning: yadm repository already initialized. Forcing overwrite."
  yadm clone --force "$REPO_URL" || {
    echo "Error: Failed to clone dotfiles repository."
    exit 1
  }
else
  yadm clone --force "$REPO_URL" || {
    echo "Error: Failed to clone dotfiles repository."
    exit 1
  }
fi

# Copy custom Zsh files
echo "Copying aliasmartin.zsh and functions.zsh..."
for file in aliasmartin.zsh functions.zsh; do
  if [[ -f ~/"$file" ]]; then
    cp ~/"$file" ~/.oh-my-zsh/custom/ || {
      echo "Error: Failed to copy ~/$file to ~/.oh-my-zsh/custom/."
      exit 1
    }
  else
    echo "Warning: ~/$file not found. Skipping."
  fi
done

echo "Setup completed successfully."
exit 0
