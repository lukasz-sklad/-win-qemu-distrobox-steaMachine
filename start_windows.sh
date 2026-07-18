#!/bin/bash

# --- Konfiguracja ścieżek ---
APP_DIR="/home/deck/Applications/win-qemu-distrobox"
DISK_PATH="$APP_DIR/windows_drive.img"
OVMF_CODE="$APP_DIR/OVMF_CODE.fd"
OVMF_VARS="$APP_DIR/OVMF_VARS.fd"

if [ ! -f "$DISK_PATH" ]; then
    echo "!!! BRAK PLIKU OBRAZU: $DISK_PATH !!!"
    exit 1
fi

# --- Parametry maszyny ---
RAM="8G"
CORES="4"

echo "=== Uruchamianie Windows (QEMU) z obrazu na NVMe ==="

# Uruchamiamy przeglądarkę okna w tle, która podłączy się po 2 sekundach
(sleep 2 && remote-viewer spice://127.0.0.1:5900) &

qemu-system-x86_64 \
  -enable-kvm \
  -machine q35 \
  -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp $CORES \
  -m $RAM \
  -vga virtio \
  -spice port=5900,addr=127.0.0.1,disable-ticketing=on \
  -device virtio-serial-pci \
  -device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0 \
  -chardev spicevmc,id=spicechannel0,name=vdagent \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS" \
  -device ahci,id=ahci0 \
  -drive file="$DISK_PATH",format=raw,if=none,id=drive0 \
  -device ide-hd,bus=ahci0.0,drive=drive0 \
  -netdev user,id=net0 -device e1000,netdev=net0 \
  -usb \
  -device qemu-xhci,id=usb-bus \
  -device usb-host,vendorid=0x045e,productid=0x0b12,guest-reset=false \
  -device usb-tablet \
  -audiodev pa,id=snd0 \
  -device intel-hda -device hda-micro,audiodev=snd0 \
  -rtc base=localtime,clock=rt
