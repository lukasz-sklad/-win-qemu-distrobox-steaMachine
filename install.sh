#!/bin/bash

# --- Konfiguracja ---
CONTAINER_NAME="qemu-box"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/home/deck/Applications/win-qemu-distrobox"

echo "=== Instalator Środowiska Windows (QEMU + Distrobox) ==="

# 1. Sprawdzenie Distrobox
if ! command -v distrobox &> /dev/null; then
    echo "Instaluję Distrobox w ~/.local/bin..."
    curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix ~/.local
    export PATH="$HOME/.local/bin:$PATH"
fi

# 2. Tworzenie folderu aplikacji i kopiowanie plików
echo "Kopiowanie plików środowiska do $APP_DIR..."
mkdir -p "$APP_DIR"
cp "$REPO_DIR/OVMF_CODE.fd" "$APP_DIR/"
cp "$REPO_DIR/OVMF_VARS.fd" "$APP_DIR/"
cp "$REPO_DIR/start_windows.sh" "$APP_DIR/"
chmod +x "$APP_DIR/start_windows.sh"

# 3. Tworzenie kontenera
echo "Tworzę kontener $CONTAINER_NAME (Arch Linux)..."
distrobox create --name $CONTAINER_NAME --image archlinux:latest --yes

# 4. Instalacja pakietów wewnątrz kontenera
echo "Instaluję QEMU i narzędzia wewnątrz kontenera..."
distrobox enter $CONTAINER_NAME -- sudo pacman -Syu --noconfirm
distrobox enter $CONTAINER_NAME -- sudo pacman -S --noconfirm qemu-desktop virt-viewer dnsmasq spice-vdagent

echo ""
echo "=== Instalacja zakończona pomyślnie! ==="
echo "Twój obraz dysku znajduje się w: $APP_DIR/windows_drive.img"
echo "Aby uruchomić Windowsa, wpisz w terminalu:"
echo "xhost +local: && distrobox enter $CONTAINER_NAME -- $APP_DIR/start_windows.sh"
echo ""
