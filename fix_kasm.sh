#!/bin/bash

# Sicherstellen, dass das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führen Sie dieses Skript mit sudo aus: sudo bash fix_kasm.sh"
  exit 1
fi

echo "=== Kasm Token Reparatur gestartet ==="

echo "[1/5] Stoppe randalierende Container (Guac, RDP)..."
docker stop kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway || true

echo "[2/5] Starte Kasm API und Proxy neu (beseitigt den 502-Fehler)..."
docker restart kasm_api kasm_proxy

echo "[3/5] Lese PERMANENTES Token aus der Agent-Konfiguration..."
# UPDATE: Wir suchen jetzt gezielt nach 'manager_token:' !
MANAGER_TOKEN=$(grep -m 1 'manager_token:' /opt/kasm/current/conf/app/agent/*.yaml | awk '{print $2}' | tr -d '"' | tr -d "'")

if [ -z "$MANAGER_TOKEN" ]; then
  echo "FEHLER: Konnte das permanente Token nicht finden! Breche ab."
  exit 1
fi
echo "-> Permanentes Token erfolgreich gefunden!"

echo "[4/5] Repariere die Konfigurationsdateien..."

for file in /opt/kasm/current/conf/app/guac/*.yaml /opt/kasm/current/conf/app/rdp_gateway/*.yaml /opt/kasm/current/conf/app/rdp_https_gateway/*.yaml; do
    if [ -f "$file" ]; then
        echo "Patche Datei: $file"
        # 1. Setze das richtige Master-Passwort
        sed -i -E 's|^([[:space:]]*manager_token:).*|\1 "'"$MANAGER_TOKEN"'"|' "$file"
        # 2. Lösche den abgelaufenen temporären Ausweis, damit Kasm gezwungen wird, einen neuen zu holen!
        sed -i -E 's|^([[:space:]]*token:).*|\1 ""|' "$file"
    fi
done

echo "[5/5] Starte reparierte Container..."
docker start kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway

echo "=== Reparatur abgeschlossen! ==="
echo "Die Kasm-Weboberfläche sollte in etwa 15 bis 30 Sekunden wieder ohne 502-Fehler erreichbar sein."
