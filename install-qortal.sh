#!/bin/bash

# Veendu, et skript käivitatakse root-õigustega (sudo abil)
if [ "$EUID" -ne 0 ]; then
  echo "Palun käivita see skript sudo'ga: sudo ./install-qortal.sh"
  exit 1
fi

echo "1. Uuendan süsteemi pakid ja paigaldan vajalikud sõltuvused (Java, curl, jq, unzip)..."
apt update && apt upgrade -y
apt install -y curl wget jq unzip openjdk-21-jre-headless

echo "2. Loon Qortali kasutaja ja kataloogi..."
useradd -r -m -d /opt/qortal -s /bin/bash qortal 2>/dev/null || true
mkdir -p /opt/qortal
cd /opt/qortal

echo "3. Laadin alla viimase Qortal Core paketi..."
QORTAL_URL=$(curl -s https://api.github.com/repos/Qortal/qortal/releases/latest | grep "browser_download_url" | cut -d '"' -f 4 | grep ".zip" | head -n 1)

if [ -z "$QORTAL_URL" ]; then
  echo "Ei suutnud automaatselt GitHubist Qortali linki leida, kasutan vaikimisi varuaadressi..."
  QORTAL_URL="https://github.com/Qortal/qortal/releases/latest/download/qortal.zip"
fi

wget -O qortal.zip "$QORTAL_URL"
unzip -o qortal.zip
rm -f qortal.zip

# Anname õigused qortal kasutajale
chown -R qortal:qortal /opt/qortal

echo "4. Loon systemd teenuse Qortali automaatseks käivitamiseks..."
cat << 'EOF' > /etc/systemd/system/qortal.service
[Unit]
Description=Qortal Core Daemon
After=network.target

[Service]
User=qortal
WorkingDirectory=/opt/qortal
ExecStart=/usr/bin/java -jar qortal.jar
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "5. Aktiveerin ja käivitan Qortali teenuse..."
systemctl daemon-reload
systemctl enable qortal.service
systemctl start qortal.service

echo "Valmis! Qortal on paigaldatud ja töötab taustal."
echo "Selle olekut saad kontrollida käsuga: sudo systemctl status qortal"
