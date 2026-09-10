#!/bin/bash
set -euo pipefail

# governer gpu clock boost
sudo sed -i '/^\[frequency-range\]/,/^\[/ s/^max = [0-9]*/max = 2230/' /etc/cyan-skillfish-governor-smu/config.toml
sudo sed -i '/frequency = 2000/{n;s/voltage = [0-9]*/voltage = 1000/}' /etc/cyan-skillfish-governor-smu/config.toml
cat <<'EOF' | sudo tee -a /etc/cyan-skillfish-governor-smu/config.toml

[[safe-points]]
frequency = 2050
voltage = 1050

[[safe-points]]
frequency = 2100
voltage = 1050

[[safe-points]]
frequency = 2125
voltage = 1050

[[safe-points]]
frequency = 2150
voltage = 1100

[[safe-points]]
frequency = 2200
voltage = 1100

[[safe-points]]
frequency = 2230
voltage = 1100

[[safe-points]]
frequency = 2300
voltage = 1150
EOF
sudo systemctl restart cyan-skillfish-governor-smu

# 8 core cpu unlock
[ -d bc250-core-cu-unlock ] || git clone https://github.com/GabriWar/bc250-core-cu-unlock
cd bc250-core-cu-unlock
sudo systemctl stop cyan-skillfish-governor-smu
sudo ./bc250-8core-unlock.sh status  # show the current mask
sudo ./bc250-8core-unlock.sh apply   # unlock now
sudo ./bc250-8core-unlock.sh install # persist: installs and enables a systemd unit
sudo systemctl start cyan-skillfish-governor-smu
cd ..

# 24+ ~40 cu gpu unlock
echo "Do: e - w - i witin bc250-cu-live-manager.sh"
curl -L -o bc250-cu-live-manager.sh https://raw.githubusercontent.com/WinnieLV/bc250-cu-live-manager/refs/heads/main/bc250-cu-live-manager.sh
chmod +x bc250-cu-live-manager.sh
sudo ./bc250-cu-live-manager.sh

# buddy for zswap btrfs swapfile watchdog
[ -d bc250-buddy ] || git clone https://github.com/samedayhurt/bc250-buddy
cd bc250-buddy

# zswap + btrfs swapfile
BC250_ASSUME_YES=1 ./install.sh mem

# watchdog: optional: resets hardlock and logs heartbeat (sensor temperature/power tracking)
BC250_ASSUME_YES=1 ./install.sh watchdog

echo ""
echo "Done. Please reboot."
