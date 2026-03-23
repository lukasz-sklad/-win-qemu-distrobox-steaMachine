#!/bin/bash

# --- Konfiguracja ścieżek ---
BIN_DIR="/home/deck/bin"
# Twoja obecna polska wersja (dokładna nazwa z dysku)
WIN_ISO_PL="$BIN_DIR/26100.1742.240906-0331.ge_release_svc_refresh_CLIENT_IOT_LTSC_EVAL_x64FRE_en-us.iso"
# Nazwa dla wersji pobieranej automatycznie (LTSC 2024 Evaluation)
WIN_ISO_EVAL="$BIN_DIR/en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso"
VIRTIO_ISO="$BIN_DIR/virtio-win-0.1.285.iso"
OVMF_CODE="$BIN_DIR/OVMF_CODE.fd"
OVMF_VARS="$BIN_DIR/OVMF_VARS.fd"
DISK_PATH="/dev/sda"

# --- Sprawdzanie obrazu ISO ---
if [ -f "$WIN_ISO_PL" ]; then
    WIN_ISO="$WIN_ISO_PL"
elif [ -f "$WIN_ISO_EVAL" ]; then
    WIN_ISO="$WIN_ISO_EVAL"
else
    echo "!!! BRAK OBRAZU WINDOWS ISO !!!"
    echo "Nie znaleziono pliku ISO w $BIN_DIR"
    read -p "Czy chcesz pobrać oficjalną wersję Windows 11 IoT LTSC 2024 Eval? (y/N): " DL_CONFIRM
    if [[ "$DL_CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Pobieranie obrazu (ok. 5GB)..."
        # Link do oficjalnej wersji Evaluation (może wygasnąć, ale to obecnie najstabilniejszy link)
        wget -O "$WIN_ISO_EVAL" "https://software-static.download.prss.microsoft.com/dblo/9b376288-6677-4482-841f-133c94f57c8d/26100.1.240331-1435.ge_release_CLIENT_IOT_LTSC_EVAL_x64FRE_en-us.iso"
        WIN_ISO="$WIN_ISO_EVAL"
    else
        echo "Błąd: Brak systemu do zainstalowania. Wyjdź."
        exit 1
    fi
fi

# --- Sprawdzanie obrazu VirtIO ---
if [ ! -f "$VIRTIO_ISO" ]; then
    echo "!!! BRAK STEROWNIKÓW VIRTIO !!!"
    echo "Nie znaleziono pliku $VIRTIO_ISO"
    read -p "Czy chcesz pobrać sterowniki VirtIO (wersja 0.1.285)? (y/N): " VIRT_CONFIRM
    if [[ "$VIRT_CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Pobieranie sterowników VirtIO..."
        wget -O "$VIRTIO_ISO" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso"
    fi
    # Sprawdzamy ponownie po próbie pobrania
    if [ ! -f "$VIRTIO_ISO" ]; then
        echo "OSTRZEŻENIE: Brak pliku sterowników VirtIO."
        echo "Możesz go pobrać ręcznie z archiwum:"
        echo "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/"
        echo "Wymagany plik: virtio-win-0.1.285.iso"
        # Nie przerywamy skryptu, bo może użytkownik uruchamia Windowsa z dysku (bez ISO)
    fi
fi

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

# --- Tryb Instalacji ---
read -p "Czy chcesz uruchomić instalator (boot z ISO)? (y/N): " INSTALL_MODE
BOOT_OPTS="-boot c"
ISO_OPTS=""

if [[ "$INSTALL_MODE" =~ ^[Yy]$ ]]; then
    echo "--- TRYB INSTALACJI AKTYWNY ---"
    # Używamy AHCI (SATA) - Windows 11 ma do tego wbudowane sterowniki
    BOOT_OPTS="-boot menu=on"
    ISO_OPTS="-device ahci,id=ahci0 "
    ISO_OPTS+="-drive file=$WIN_ISO,if=none,id=win_cd,media=cdrom -device ide-cd,bus=ahci0.0,drive=win_cd,bootindex=0 "
    ISO_OPTS+="-drive file=$VIRTIO_ISO,if=none,id=virt_cd,media=cdrom -device ide-cd,bus=ahci0.1,drive=virt_cd"
fi

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
  $ISO_OPTS \
  #-netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -device qemu-xhci,id=usb-bus \
  -device usb-host,bus=usb-bus.0,hostbus=1,hostport=1.2,guest-reset=false \
  -usb \
  -device usb-tablet \
  -rtc base=localtime,clock=rt \
  $BOOT_OPTS
