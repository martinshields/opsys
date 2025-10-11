#!/bin/bash

# Prompt user for confirmation before running the command
echo "This script will download and execute omarchy-cleaner.sh from https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh"
echo "It is recommended to review the script before running it. Would you like to proceed? (y/n)"
read -p "Enter your choice: " choice

if [[ "$choice" =~ ^[Yy]$ ]]; then
    echo "Running the command..."
    curl -fsSL https://raw.githubusercontent.com/maxart/omarchy-cleaner/main/omarchy-cleaner.sh | bash
else
    echo "Operation cancelled by user."
    exit 1
fi