#!/bin/bash

# --- Konfiguracja ścieżek ---
BIN_DIR="/home/deck/bin"
WIN_ISO="$BIN_DIR/pl_windows_11_iot_enterprise_ltsc_2024_with_update_26100.3194_x64.iso"
VIRTIO_ISO="$BIN_DIR/virtio-win-0.1.285.iso"
OVMF_CODE="$BIN_DIR/OVMF_CODE.fd"
OVMF_VARS="$BIN_DIR/OVMF_VARS.fd"
DISK_PATH="/dev/sda"

# --- Test prędkości dysku ---
echo "--- Sprawdzanie prędkości dysku $DISK_PATH ---"
# Testujemy 300MB, żeby nie trwało to zbyt długo
SPEED_RAW=$(dd if="$DISK_PATH" of=/dev/null bs=1M count=300 2>&1 | tail -1 | awk '{print $(NF-1)}')
# Zamiana przecinka na kropkę dla porównania liczbowego
SPEED=$(echo "$SPEED_RAW" | tr ',' '.')
# Zaokrąglenie do liczby całkowitej (usuwamy to co po kropce)
SPEED_INT=${SPEED%.*}

echo "Wykryta prędkość: $SPEED_RAW MB/s"

if [ "$SPEED_INT" -lt 100 ]; then
    echo "!!! OSTRZEŻENIE: Dysk działa w trybie USB 2.0 (wolno) !!!"
    echo "Uruchomienie Windowsa przy tej prędkości może uszkodzić system plików."
    read -p "Czy na pewno chcesz kontynuować? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Anulowano uruchomienie Windowsa."
        exit 1
    fi
else
    echo "Prędkość OK (USB 3.0). Uruchamiam Windows..."
fi

# --- Parametry maszyny ---
RAM="4G"
CORES="4"

# --- Uruchomienie QEMU (Tryb Port Passthrough) ---
# hostbus=1, hostport=1.2: Precyzyjna ścieżka z Twojego lsusb -t

qemu-system-x86_64 \
  -enable-kvm \
  -machine q35 \
  -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp $CORES \
  -m $RAM \
  -vga qxl \
  -spice port=5900,addr=127.0.0.1,disable-ticketing=on \
  -device virtio-serial-pci \
  -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
  -chardev spicevmc,id=spicechannel0,name=vdagent \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  -device virtio-scsi-pci,id=scsi0 \
  -drive file="$DISK_PATH",format=raw,if=virtio,id=drive0 \
  -device qemu-xhci,id=usb-bus \
  -device usb-host,bus=usb-bus.0,hostbus=1,hostport=1.2,guest-reset=false \
  -usb \
  -device usb-tablet \
  -rtc base=localtime,clock=rt \
  -boot c
