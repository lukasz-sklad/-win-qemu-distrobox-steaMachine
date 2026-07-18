#!/bin/bash

CONTAINER_NAME="qemu-box"
MAX_RETRIES=3

echo "=== Autostart kontenera Distrobox: $CONTAINER_NAME ==="

for ((i=1; i<=MAX_RETRIES; i++)); do
    echo "Próba $i uruchomienia kontenera..."
    
    # Wywołujemy start (podman lub docker)
    podman start "$CONTAINER_NAME" > /dev/null 2>&1 || docker start "$CONTAINER_NAME" > /dev/null 2>&1
    
    # Weryfikacja: sprawdzamy bezpośrednio na liście czy kontener na pewno ma status "Up"
    STATUS=$(podman ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" 2>/dev/null || docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" 2>/dev/null)
    
    if echo "$STATUS" | grep -q "Up"; then
        echo "Sukces! Kontener $CONTAINER_NAME został prawidłowo uruchomiony (Status: $STATUS)."
        exit 0
    fi
    
    echo "Kontener nie podniósł się prawidłowo. Czekam 5 sekund przed kolejną próbą..."
    sleep 5
done

echo "Ostrzeżenie: Nie udało się uruchomić kontenera $CONTAINER_NAME po $MAX_RETRIES próbach."
echo "Zakończono pętlę. Pomijam proces, aby nie blokować wczytywania systemu."
exit 0
