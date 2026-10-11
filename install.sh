#!/usr/bin/env bash
#
# ReconShadow installer - sets up the ProjectDiscovery toolchain.
# Author: Jineeb J N
#
set -euo pipefail

echo "[*] ReconShadow installer"

SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi

apt_install() {
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get install -y "$@"
  fi
}

# ---------- base dependencies ----------
if command -v apt-get >/dev/null 2>&1; then
  $SUDO apt-get update -y
  command -v go >/dev/null 2>&1 || apt_install golang-go
  command -v jq >/dev/null 2>&1 || apt_install jq
  # Build deps for naabu (libpcap) - harmless if already present.
  apt_install gcc libpcap-dev
else
  echo "[!] apt-get not found. Install Go and jq manually, then re-run."
fi

if ! command -v go >/dev/null 2>&1; then
  echo "[-] Go is required but not installed. Install it and re-run." >&2
  exit 1
fi

export PATH="$PATH:$(go env GOPATH)/bin"

install_go_tool() {
  local name="$1" pkg="$2"
  if command -v "$name" >/dev/null 2>&1; then
    echo "[=] $name already installed"
  else
    echo "[*] Installing $name..."
    if go install -v "$pkg" >/dev/null 2>&1; then
      echo "[+] $name installed"
    else
      echo "[-] Failed to install $name" >&2
    fi
  fi
}

install_go_tool subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
install_go_tool dnsx      github.com/projectdiscovery/dnsx/cmd/dnsx@latest
install_go_tool httpx     github.com/projectdiscovery/httpx/cmd/httpx@latest
install_go_tool naabu     github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
install_go_tool nuclei    github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
install_go_tool gau       github.com/lc/gau/v2/cmd/gau@latest

# Pull nuclei templates (needed for takeover and vulnerability scans).
if command -v nuclei >/dev/null 2>&1; then
  echo "[*] Updating nuclei templates..."
  nuclei -update-templates >/dev/null 2>&1 || true
fi

echo
echo "[+] Done."
echo "    If the tools are not on your PATH, add the Go bin directory:"
echo "      export PATH=\"\$PATH:\$(go env GOPATH)/bin\""
echo "    Then run:  ./reconshadow.sh -d example.com"
