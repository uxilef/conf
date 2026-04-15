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

echo "[3/5] Lese Token aus der Agent-Konfiguration..."
# UPDATE: Korrekter Pfad in den Unterordner /agent/ mit Wildcard!
TOKEN=$(grep -m 1 'token:' /opt/kasm/current/conf/app/agent/*.yaml | awk '{print $2}' | tr -d '"' | tr -d "'")

# Kurzer Sicherheitscheck, ob das Token wirklich gefunden wurde
if [ -z "$TOKEN" ]; then
  echo "FEHLER: Konnte das Token nicht finden! Breche ab."
  exit 1
fi
echo "-> Token erfolgreich gefunden!"

echo "[4/5] Injiziere Token in die Konfigurationsdateien..."
# Wir patchen die Dateien direkt in ihren jeweiligen Unterordnern
sed -i -E 's|^([[:space:]]*token:).*|\1 "'"$TOKEN"'"|' /opt/kasm/current/conf/app/guac/*.yaml
sed -i -E 's|^([[:space:]]*token:).*|\1 "'"$TOKEN"'"|' /opt/kasm/current/conf/app/rdp_gateway/*.yaml
sed -i -E 's|^([[:space:]]*token:).*|\1 "'"$TOKEN"'"|' /opt/kasm/current/conf/app/rdp_https_gateway/*.yaml

echo "[5/5] Starte reparierte Container..."
docker start kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway

echo "=== Reparatur abgeschlossen! ==="
echo "Die Kasm-Weboberfläche sollte in etwa 15 bis 30 Sekunden wieder ohne 502-Fehler erreichbar sein."
