#!/usr/bin/env bash
set -euo pipefail

# ---------- Helper functions ----------
log()  { echo -e "\033[1;32m[OK]\033[0m $*"; }
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

export DEBIAN_FRONTEND=noninteractive

# ---------- Install Docker ----------
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker is already installed: $(docker --version 2>/dev/null || true)"
  else
    info "Installing Docker CE from the official repository..."
    sudo apt-get remove -y docker docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true

    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
      curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    . /etc/os-release
    ARCH="$(dpkg --print-architecture)"
    REPO_LINE="deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable"
    if ! grep -qF "$REPO_LINE" /etc/apt/sources.list.d/docker.list 2>/dev/null; then
      echo "$REPO_LINE" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl restart docker
    log "Docker installed: $(docker --version)"
  fi

  # Add the current user to the docker group for non-root usage
  if id -nG "$USER" 2>/dev/null | grep -qw docker; then
    log "User is already in the docker group."
  else
    info "Adding user '$USER' to the docker group..."
    sudo usermod -aG docker "$USER" || warn "Failed to add user to docker group."
    warn "Log out and log back in to apply the docker group."
  fi
}

# ---------- Install Docker Compose ----------
install_compose() {
  # Prefer Compose v2 (docker compose)
  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose (v2) is already installed: $(docker compose version 2>/dev/null | head -n1)"
    return
  fi
  # Legacy docker-compose binary
  if command -v docker-compose >/dev/null 2>&1; then
    log "Docker Compose (legacy) is already installed: $(docker-compose --version)"
    return
  fi

  info "Installing Docker Compose plugin..."
  sudo apt-get update -y
  sudo apt-get install -y docker-compose-plugin
  log "Docker Compose installed: $(docker compose version 2>/dev/null | head -n1)"
}

# ---------- Install Python ----------
install_python() {
  if command -v python3 >/dev/null 2>&1; then
    log "Python3 is already installed: $(python3 --version)"
  else
    info "Installing the latest Python version..."
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip python3-venv
    log "Python installed: $(python3 --version)"

    # Ensure pip and venv are present even if Python was already installed
    if ! python3 -m pip --version >/dev/null 2>&1; then
      info "Installing python3-pip..."
      sudo apt-get install -y python3-pip || true
    fi
    if ! python3 -m venv -h >/dev/null 2>&1; then
      info "Installing python3-venv..."
      sudo apt-get install -y python3-venv
    fi
  fi
}

# ---------- Install Django ----------
install_django() {
  if python3 -c 'import django' >/dev/null 2>&1; then
    log "Django is already installed: $(python3 -c 'import django; print(django.get_version())')"
  else
    info "Installing Django..."
    sudo apt-get update -y
    sudo apt-get install -y python3-django
    log "Django installed: $(python3 -c 'import django; print(django.get_version())')"
  fi
}

# ---------- Main ----------
main() {
  info "=== Starting dev tools installation ==="
  install_docker
  install_compose
  install_python
  install_django
  info "=== All tools installed successfully ==="
}

main "$@"