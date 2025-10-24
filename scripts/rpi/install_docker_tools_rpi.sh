#!/bin/bash
# Check and install Docker, Docker Compose, and LazyDocker on Raspberry Pi OS (Debian-based)

set -e

installed_tools=()
already_tools=()

check_command() {
  command -v "$1" >/dev/null 2>&1
}

install_docker() {
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$USER"
  installed_tools+=("Docker")
}

install_docker_compose() {
  echo "Installing Docker Compose..."
  if ! check_command pip3; then
    sudo apt update && sudo apt install -y python3-pip
  fi
  sudo pip3 install docker-compose
  installed_tools+=("Docker Compose")
}

install_lazydocker() {
  echo "Installing LazyDocker..."
  arch=$(uname -m)
  case "$arch" in
    aarch64)
      url="https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_Linux_arm64.tar.gz"
      ;;
    armv7l|armv6l)
      url="https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_Linux_armv6.tar.gz"
      ;;
    *)
      echo "❌ Unsupported architecture: $arch"
      exit 1
      ;;
  esac

  curl -Lo lazydocker.tar.gz "$url"
  tar xf lazydocker.tar.gz
  sudo mv lazydocker /usr/local/bin/
  rm lazydocker.tar.gz
  installed_tools+=("LazyDocker")
}

echo "🔍 Checking installations on Raspberry Pi OS..."

if check_command docker; then
  echo "✅ Docker is already installed."
  already_tools+=("Docker")
else
  install_docker
fi

if check_command docker-compose; then
  echo "✅ Docker Compose is already installed."
  already_tools+=("Docker Compose")
else
  install_docker_compose
fi

if check_command lazydocker; then
  echo "✅ LazyDocker is already installed."
  already_tools+=("LazyDocker")
else
  install_lazydocker
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Installation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#installed_tools[@]} -gt 0 ]; then
  echo "🆕 Installed:"
  for tool in "${installed_tools[@]}"; do
    echo "   • $tool"
  done
else
  echo "🆕 Installed: None"
fi

if [ ${#already_tools[@]} -gt 0 ]; then
  echo "✅ Already Installed:"
  for tool in "${already_tools[@]}"; do
    echo "   • $tool"
  done
else
  echo "✅ Already Installed: None"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 All checks complete!"
echo "⚠️ Log out and back in for Docker group changes to take effect."
