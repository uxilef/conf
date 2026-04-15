#!/bin/bash

# Sicherstellen, dass das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führen Sie dieses Skript mit sudo aus: sudo bash fix_kasm.sh"
  exit 1
fi

echo "=== Kasm Token Reparatur gestartet ==="

echo "[1/4] Stoppe randalierende Container (Guac, RDP)..."
docker stop kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway || true

echo "[2/4] Starte Kasm API und Proxy neu (beseitigt den 502-Fehler)..."
docker restart kasm_api kasm_proxy

# HIER IST IHR ORIGINALES MASTER-TOKEN DIREKT EINGETRAGEN:
MANAGER_TOKEN="6iDd2HS3U0FR5EVfP8NS"

echo "[3/4] Schreibe Ihr Master-Token in die Konfigurationsdateien..."

for file in /opt/kasm/current/conf/app/guac/*.yaml /opt/kasm/current/conf/app/rdp_gateway/*.yaml /opt/kasm/current/conf/app/rdp_https_gateway/*.yaml; do
    if [ -f "$file" ]; then
        echo "Repariere Datei: $file"
        # 1. Setze das richtige Master-Passwort
        sed -i -E 's|^([[:space:]]*manager_token:).*|\1 "'"$MANAGER_TOKEN"'"|' "$file"
        # 2. Lösche den abgelaufenen temporären Ausweis, damit Kasm gezwungen wird, einen neuen zu holen!
        sed -i -E 's|^([[:space:]]*token:).*|\1 ""|' "$file"
    fi
done

echo "[4/4] Starte reparierte Container..."
docker start kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway

echo "=== Reparatur abgeschlossen! ==="
echo "Geben Sie Kasm jetzt 15 Sekunden Zeit, dann ist die Webseite wieder erreichbar."
