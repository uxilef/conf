#!/bin/bash

# Sicherstellen, dass das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führen Sie dieses Skript mit sudo aus: sudo ./fix_kasm_workspaces.sh"
  exit 1
fi

echo "=== Kasm Workspace Reparatur gestartet ==="

# IHR ORIGINALES SERVICE REGISTRATION TOKEN
SERVICE_TOKEN="w4bgxcZ9vy6Ewj8iXyM1"

echo "[1/3] Stoppe die Workspace-Container (Guac, RDP)..."
docker stop kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway || true

echo "[2/3] Schreibe das Service Registration Token in die Konfigurationsdateien..."

# Gehe durch alle drei Ordner und ersetze/setze den token-Wert
for dir in guac rdp_gateway rdp_https_gateway; do
    for file in /opt/kasm/current/conf/app/$dir/*.yaml; do
        if [ -f "$file" ]; then
            echo "-> Repariere Datei: $file"
            # Sucht nach der Zeile mit 'token:' und trägt Ihr festes Passwort ein
            sed -i -E 's|^([[:space:]]*token:).*|\1 "'"$SERVICE_TOKEN"'"|' "$file"
        fi
    done
done

echo "[3/3] Starte die reparierten Container..."
docker start kasm_guac kasm_rdp_gateway kasm_rdp_https_gateway

echo "=== Reparatur erfolgreich abgeschlossen! ==="
echo "Die Container holen sich jetzt frische Ausweise bei der API."
echo "Ihre Workspaces sollten in ca. 10 Sekunden wieder starten können!"
