#!/bin/bash

echo "=== Konfiguracja usługi systemd dla autostartu qemu-box ==="

SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/qemu-box.service"
APP_DIR="/home/deck/Applications/win-qemu-distrobox"

# Upewnienie się, że folder na usługi użytkownika istnieje
mkdir -p "$SERVICE_DIR"

# Generowanie pliku usługi
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Start Distrobox qemu-box container
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$APP_DIR/services.sh

[Install]
WantedBy=default.target
EOF

echo "Utworzono plik usługi w: $SERVICE_FILE"

# Przeładowanie deamona systemd i aktywacja usługi
systemctl --user daemon-reload
systemctl --user enable qemu-box.service
systemctl --user start qemu-box.service

echo ""
echo "Usługa qemu-box.service została poprawnie załadowana, dodana do autostartu i uruchomiona!"
