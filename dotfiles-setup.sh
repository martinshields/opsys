#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/martinshields/dotfiles.git"
REPO_NAME="dotfiles"


is_yadm_installed() {
  pacman -Qi "yadm" &> /dev/null
}

if ! is_yadm_installed; then
  echo "Install yadm first"
  exit 1
fi

cd ~
#Remove every thing in the nvim dir befor installing my ver.

  echo "Removing old nvim file to install mine."
  rm -rf ~/.config/nvim/* ~/.config/nvim/.* 2>/dev/null

# installing my yadm dotfiles.  
  echo "Install dotfiles"
  yadm clone "$REPO_URL"

# move aliasmartin.zsh and function.zsh
  echo "copying over aliasmartin.zsh and functions.zsh"
 cp ~/aliasmartin.zsh ~/.oh-my-zsh/custom/aliasmartin.zsh
 cp ~/functions.zsh ~/.oh-my-zsh/custom/functions.zsh
exit 1

