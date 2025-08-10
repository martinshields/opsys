#!/bin/bash

REPO_URL="https://github.com/martinshields/dotfiles.git"
OH_MY_ZSH_DIR=~/.oh-my-zsh
NVIM_CONFIG_DIR=~/.config/nvim
LOG_FILE=~/dotfiles_setup.log

# Log function
log() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Check if yadm is installed
is_yadm_installed() {
    command -v yadm >/dev/null 2>&1
}

# Check if Zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
    log "Error: Zsh is not installed. Please install Zsh first."
    exit 1
fi

# Check if yadm is installed
if ! is_yadm_installed; then
    log "Error: yadm is not installed. Please install yadm first."
    exit 1
fi

# Check network connectivity
ping -c 1 github.com >/dev/null 2>&1 || {
    log "Error: No internet connection. Please check your network."
    exit 1
}

# Remove existing oh-my-zsh directory if it exists
if [[ -d "$OH_MY_ZSH_DIR" ]]; then
    read -p "This will remove $OH_MY_ZSH_DIR. Continue? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log "Aborted."
        exit 1
    fi
    log "Backing up existing oh-my-zsh directory..."
    mv "$OH_MY_ZSH_DIR" "${OH_MY_ZSH_DIR}.bak-$(date +%F-%H%M%S)" || {
        log "Error: Failed to back up $OH_MY_ZSH_DIR."
        exit 1
    }
fi

# Install oh-my-zsh
log "Installing oh-my-zsh..."
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended || {
    log "Error: Failed to install oh-my-zsh."
    exit 1
}

# Remove existing Neovim configuration
if [[ -d "$NVIM_CONFIG_DIR" ]]; then
    read -p "This will remove $NVIM_CONFIG_DIR. Continue? (y/N) " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log "Aborted."
        exit 1
    fi
    log "Backing up existing Neovim configuration..."
    mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak-$(date +%F-%H%M%S)" || {
        log "Error: Failed to back up $NVIM_CONFIG_DIR."
        exit 1
    }
fi

# Clone dotfiles with yadm
log "Cloning dotfiles (overwriting existing files)..."
if yadm status >/dev/null 2>&1; then
    log "Warning: yadm repository already initialized. Forcing overwrite."
    yadm clone -f "$REPO_URL" || {
        log "Error: Failed to clone dotfiles from $REPO_URL."
        exit 1
    }
else
    yadm clone -f "$REPO_URL" || {
        log "Error: Failed to clone dotfiles from $REPO_URL."
        exit 1
    }
fi

# Ensure oh-my-zsh custom directory exists
mkdir -p "$OH_MY_ZSH_DIR/custom/" || {
    log "Error: Failed to create $OH_MY_ZSH_DIR/custom/."
    exit 1
}

# Copy custom Zsh files
log "Copying aliasmartin.zsh and functions.zsh..."
for file in aliasmartin.zsh functions.zsh; do
    if [[ -f ~/"$file" ]]; then
        cp ~/"$file" "$OH_MY_ZSH_DIR/custom/" || {
            log "Error: Failed to copy ~/$file to $OH_MY_ZSH_DIR/custom/."
            exit 1
        }
    else
        log "Warning: ~/$file not found. Skipping."
    fi
done

log "Setup completed successfully."
exit 0
