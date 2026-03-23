#!/bin/bash

# --- Konfiguracja ścieżek ---
BIN_DIR="/home/deck/bin"
# TWOJA AKTUALNA POLSKA WERSJA (już jest na dysku)
WIN_ISO_11="$BIN_DIR/ventoy-deck/pl_11_iot_enterprise_ltsc_2024_with_update_26100.3194_x64.iso"
VIRTIO_ISO="$BIN_DIR/ventoy-deck/alcohol120.iso"
OVMF_CODE="$BIN_DIR/OVMF_CODE.fd"
OVMF_VARS="$BIN_DIR/OVMF_VARS.fd"
DISK_PATH="/dev/sdb"

# --- Sprawdzanie obrazu ISO ---
if [ -f "$WIN_ISO_11" ]; then
    echo "Znaleziono obraz: $WIN_ISO_11"
    WIN_ISO="$WIN_ISO_11"
else
    echo "!!! BRAK OBRAZU WINDOWS 11 ISO !!!"
    echo "Nie znaleziono pliku ISO w $BIN_DIR"
    echo "Twój link pCloud wymaga otwarcia w przeglądarce i ręcznego pobrania:"
    echo "Link: https://e.pcloud.link/publink/show?code=XZeXBGZxvKnNTRkcx5EFgynUM1rafPfdCjy"
    exit 1
fi

# --- Sprawdzanie obrazu VirtIO ---
if [ ! -f "$VIRTIO_ISO" ]; then
    echo "!!! BRAK STEROWNIKÓW VIRTIO !!!"
    read -p "Czy chcesz pobrać sterowniki VirtIO? (y/N): " VIRT_CONFIRM
    if [[ "$VIRT_CONFIRM" =~ ^[Yy]$ ]]; then
        wget -O "$VIRTIO_ISO" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso"
    fi
fi

# --- Test prędkości dysku ---
echo "--- Sprawdzanie prędkości dysku $DISK_PATH ---"
SPEED_RAW=$(dd if="$DISK_PATH" of=/dev/null bs=1M count=300 2>&1 | tail -1 | awk '{print $(NF-1)}')
SPEED=$(echo "$SPEED_RAW" | tr ',' '.')
SPEED_INT=${SPEED%.*}
echo "Wykryta prędkość: $SPEED_RAW MB/s"

if [ "$SPEED_INT" -lt 100 ]; then
    echo "!!! OSTRZEŻENIE: Dysk działa w trybie USB 2.0 (wolno) !!!"
    echo "Błędy aktualizacji Windowsa biorą się zazwyczaj z wolnego dysku."
    read -p "Czy na pewno chcesz kontynuować? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# --- Parametry maszyny ---
RAM="4G"
CORES="4"

# --- Tryb Instalacji i Napędy ISO ---
read -p "Czy chcesz uruchomić instalator (boot z ISO)? (y/N): " INSTALL_MODE
BOOT_OPTS="-boot c"
ISO_OPTS="-device ahci,id=ahci0 "

# Zawsze dołączaj Alcohol120/VirtIO (bus 0.0)
ISO_OPTS+="-drive file=$VIRTIO_ISO,if=none,id=virt_cd,media=cdrom -device ide-cd,bus=ahci0.0,drive=virt_cd "

if [[ "$INSTALL_MODE" =~ ^[Yy]$ ]]; then
    echo "--- TRYB INSTALACJI AKTYWNY ---"
    BOOT_OPTS="-boot menu=on"
    # Instalator Windowsa (bus 0.1)
    ISO_OPTS+="-drive file=$WIN_ISO,if=none,id=win_cd,media=cdrom -device ide-cd,bus=ahci0.1,drive=win_cd,bootindex=0 "
fi

# --- Fizyczna nagrywarka ---
PHYS_CD_OPTS=""
if [ -e "/dev/sr0" ]; then
    echo "--- Wykryto fizyczną nagrywarkę: /dev/sr0 ---"
    echo "Upewnij się, że masz uprawnienia: sudo chmod 666 /dev/sr0"
    # Fizyczny napęd na tym samym kontrolerze ahci0, ale na innym kanale (bus 0.2)
    PHYS_CD_OPTS="-drive file=/dev/sr0,format=raw,if=none,id=real_cd,media=cdrom -device ide-cd,bus=ahci0.2,drive=real_cd"
fi

# --- Uruchomienie QEMU ---
# PAMIĘTAJ: Zakomentuj poniższą linię z '-netdev', wyłącz internet
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
  $ISO_OPTS \
  $PHYS_CD_OPTS \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -usb \
  -device qemu-xhci,id=usb-bus \
  -device usb-host,vendorid=0x045e,productid=0x0b12,guest-reset=false \
  -device usb-tablet \
  -rtc base=localtime,clock=rt \
  $BOOT_OPTS
