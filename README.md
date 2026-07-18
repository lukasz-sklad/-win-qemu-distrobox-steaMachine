# Windows on Steam Machine (QEMU + Distrobox)

To repozytorium pozwala przenieść fizyczną instalację systemu Windows (np. z pendrive'a/dysku USB) bezpośrednio do ultraszybkiej wirtualnej maszyny na dysku NVMe. Całość działa wewnątrz kontenera **Distrobox**, dzięki czemu Twój główny system (SteamOS) pozostaje czysty i w 100% nienaruszony!

## Funkcjonalności
- Klonowanie fizycznego Windowsa do pliku obrazu (`.img`) z wykorzystaniem wydajności NVMe.
- Automatyczna instalacja QEMU w kontenerze (Arch Linux).
- Skrypt uruchamiający kontener automatycznie przy starcie systemu (działający nawet w domyślnym trybie Gaming Mode).
- Pełna integracja z Menu Start pulpitu KDE (skróty `.desktop` i inteligentne zarządzanie awaryjne).

## Krok po kroku: Instalacja i wdrożenie

### 1. Sklonuj system z USB do obrazu na dysku NVMe
Podłącz swój pendrive z Windowsem (zazwyczaj widnieje on jako `/dev/sda`). Nie musisz kopiować całego dysku, zwłaszcza jeśli Windows zajmuje tylko część. Wystarczy skopiować pierwsze ~160 GB (zawierające partycję bootowania EFI, Recovery oraz sam dysk C:).

Najpierw utwórz folder wdrożeniowy:
```bash
mkdir -p /home/deck/Applications/win-qemu-distrobox/
```

Następnie skopiuj pierwsze 160 GB z pamięci USB:
```bash
sudo dd if=/dev/sda of=/home/deck/Applications/win-qemu-distrobox/windows_drive.img bs=1M count=160000 status=progress
```

**⚠️ BARDZO WAŻNE:** Plik utworzony przez narzędzie `dd` z użyciem `sudo` należy do użytkownika root. Musisz przekazać do niego prawa swojemu użytkownikowi (`deck`), w przeciwnym razie QEMU wyświetli błąd **"Permission denied"**:
```bash
sudo chown deck:deck /home/deck/Applications/win-qemu-distrobox/windows_drive.img
```

### 2. Zainstaluj środowisko (Distrobox + QEMU)
Wejdź do sklonowanego repozytorium i uruchom główny instalator:
```bash
./install.sh
```
Skrypt automatycznie pobierze wymagane paczki, skopiuje pliki rozruchowe UEFI (OVMF) oraz ustawi skrypty startowe.

### 3. Skonfiguruj skróty w KDE (Opcjonalnie)
Chcesz odpalać Windowsa jak zwykłą aplikację prosto z Menu Start? Uruchom:
```bash
./menu-kde.sh
```
W Twoim menu pojawi się nowy skrót **"Windows (QEMU Distrobox)"**. Posiada on ukrytą funkcję – jeśli klikniesz na niego prawym przyciskiem myszy, zobaczysz opcję awaryjną: **"Zabij procesy QEMU i wymuś start"** (niezbędne, gdyby wirtualna maszyna nagle się zacięła).

### 4. Autostart wraz z systemem (Opcjonalnie)
Jeśli chcesz, aby kontener uruchamiał się w tle podczas ładowania całego systemu (gotowy na natychmiastowe przyjęcie Windowsa):
```bash
./setup_service.sh
```
Skrypt wygeneruje własną usługę w ramach użytkownika systemd, która będzie niezawodnie włączać kontener środowiska bez opóźniania ładowania systemu operacyjnego.

## Uruchamianie ręczne z terminala
Jeśli preferujesz linię komend, zawsze możesz odpalić system komendą:
```bash
xhost +local: && distrobox enter qemu-box -- /home/deck/Applications/win-qemu-distrobox/start_windows.sh
```
