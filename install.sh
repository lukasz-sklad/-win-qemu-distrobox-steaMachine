#!/bin/bash

# --- Konfiguracja ---
CONTAINER_NAME="qemu-box"
BIN_DIR="$HOME/bin"
REPO_DIR="$BIN_DIR/windows-qemu-distrobox"

echo "=== Instalator Środowiska Windows (QEMU + Distrobox) ==="

# 1. Sprawdzenie Distrobox
if ! command -v distrobox &> /dev/null; then
    echo "Instaluję Distrobox w ~/.local/bin..."
    curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix ~/.local
    export PATH="$HOME/.local/bin:$PATH"
fi

# 2. Tworzenie kontenera
echo "Tworzę kontener $CONTAINER_NAME (Arch Linux)..."
distrobox create --name $CONTAINER_NAME --image archlinux:latest --yes

# 3. Instalacja pakietów wewnątrz kontenera
echo "Instaluję QEMU i narzędzia wewnątrz kontenera..."
distrobox enter $CONTAINER_NAME -- sudo pacman -Syu --noconfirm
distrobox enter $CONTAINER_NAME -- sudo pacman -S --noconfirm qemu-desktop virt-viewer dnsmasq spice-vdagent

# 4. Kopiowanie skryptu startowego do bin (jeśli go tam nie ma)
cp "$REPO_DIR/start_windows.sh" "$BIN_DIR/start_windows.sh"
chmod +x "$BIN_DIR/start_windows.sh"

echo ""
echo "=== Instalacja zakończona! ==="
echo "Aby uruchomić Windowsa, użyj komendy:"
echo "xhost +local: && distrobox enter $CONTAINER_NAME -- ~/bin/start_windows.sh"
echo ""
echo "Pamiętaj o podpięciu dysku /dev/sda w trybie USB 3.0!"
