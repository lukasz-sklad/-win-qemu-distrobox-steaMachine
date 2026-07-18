#!/bin/bash

echo "=== Tworzenie skrótów KDE dla Windows QEMU ==="

APP_DIR="/home/deck/Applications/win-qemu-distrobox"
LAUNCHER_SCRIPT="$APP_DIR/run-windows.sh"
DESKTOP_FILE="$HOME/.local/share/applications/windows-qemu.desktop"

# Upewniamy się, że folder aplikacji istnieje
mkdir -p "$APP_DIR"

# 1. Tworzenie inteligentnego skryptu launchera
cat > "$LAUNCHER_SCRIPT" << 'EOF'
#!/bin/bash

CONTAINER_NAME="qemu-box"
APP_DIR="/home/deck/Applications/win-qemu-distrobox"

# Jeśli przekazano parametr --force-restart, brutalnie ubijamy QEMU
if [ "$1" == "--force-restart" ]; then
    killall qemu-system-x86_64 2>/dev/null
    sleep 2
fi

# Sprawdzamy czy kontener działa, jeśli nie - błyskawicznie go odpalamy
STATUS=$(podman ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" 2>/dev/null || docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" 2>/dev/null)
if ! echo "$STATUS" | grep -q "Up"; then
    podman start "$CONTAINER_NAME" > /dev/null 2>&1 || docker start "$CONTAINER_NAME" > /dev/null 2>&1
    sleep 1
fi

# Udzielenie dostępu do serwera X i start Windowsa
xhost +local: > /dev/null 2>&1
distrobox enter "$CONTAINER_NAME" -- "$APP_DIR/start_windows.sh"
EOF

chmod +x "$LAUNCHER_SCRIPT"

# 2. Tworzenie pliku .desktop z dodatkową opcją pod prawym klawiszem
mkdir -p "$HOME/.local/share/applications"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Windows (QEMU Distrobox)
Comment=Uruchom wirtualną maszynę z systemem Windows
Exec=$LAUNCHER_SCRIPT
Icon=computer
Terminal=false
Type=Application
Categories=System;Emulator;
Actions=ForceRestart;

[Desktop Action ForceRestart]
Name=Zabij procesy QEMU i wymuś start
Exec=$LAUNCHER_SCRIPT --force-restart
EOF

# Odświeżenie bazy aplikacji w KDE
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Gotowe! Skrót 'Windows (QEMU Distrobox)' został dodany do menu start w KDE."
echo "Kliknięcie skrótu prawym przyciskiem myszy wyświetli nową opcję awaryjnego restartu."
