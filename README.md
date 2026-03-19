# Windows on Steam Deck (QEMU + Distrobox)

Ten projekt pozwala na uruchamianie systemu Windows 11 bezpośrednio z fizycznego dysku NVMe/SSD podpiętego przez USB na Steam Decku, przy wykorzystaniu wirtualizacji KVM w kontenerze Distrobox.

## Dlaczego Distrobox?
SteamOS jest systemem typu "read-only". Distrobox pozwala na zainstalowanie QEMU i wszystkich bibliotek bez modyfikowania partycji systemowej SteamOS.

## Wymagania:
1.  **Dysk zewnętrzny:** SSD NVMe w obudowie USB lub szybki dysk SSD (podpięty jako `/dev/sda`).
2.  **Połączenie USB 3.0:** Wymagane dla stabilności (minimum 150 MB/s).
3.  **SteamOS:** Tryb Desktop.

## Instalacja:
1.  Skopiuj folder `windows-qemu-distrobox` do swojego katalogu `~/bin/`.
2.  Uruchom skrypt instalacyjny:
    ```bash
    cd ~/bin/windows-qemu-distrobox
    chmod +x install.sh
    ./install.sh
    ```

## Uruchamianie:
Aby uruchomić Windowsa, wykonaj:
```bash
xhost +local: && distrobox enter qemu-box -- ~/bin/start_windows.sh
```

## Rozwiązywanie problemów:
- **Błąd prędkości dysku:** Upewnij się, że Twój monitor/hub jest ustawiony w trybie USB 3.0. Skrypt `start_windows.sh` automatycznie sprawdza prędkość przed startem.
- **Brak obrazu (SPICE):** Jeśli okno Windowsa się nie pojawia, uruchom podgląd ręcznie:
  ```bash
  xhost +local: && distrobox enter qemu-box -- remote-viewer spice://127.0.0.1:5900
  ```

## Pliki:
- `start_windows.sh`: Główny skrypt uruchamiający QEMU.
- `OVMF_CODE.fd` / `OVMF_VARS.fd`: Pliki UEFI wymagane do bootowania Windowsa.
- `install.sh`: Automatyczny konfigurator środowiska.
