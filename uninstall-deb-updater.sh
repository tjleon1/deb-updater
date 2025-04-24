#!/bin/bash

echo "[*] Removing Deb Updater system files..."

# Remove installed scripts
sudo rm -f /usr/local/bin/deb-updater.sh
sudo rm -f /usr/local/bin/deb-updater-tray.sh

# Remove application menu and autostart entries
sudo rm -f /usr/share/applications/deb-updater.desktop
sudo rm -f /etc/xdg/autostart/deb-updater.desktop
sudo rm -f /etc/xdg/autostart/deb-updater-tray.desktop

# Prompt to remove user configuration
echo
read -p "🗑 Do you want to remove your personal configuration folder (~/.deb-updater)? [y/N]: " confirm
if [[ \"$confirm\" =~ ^[Yy]$ ]]; then
  rm -rf \"$HOME/.deb-updater\"
  echo \"[✓] Removed: ~/.deb-updater/\"
else
  echo \"[!] Skipped: ~/.deb-updater/\"
fi

echo \"[✓] Deb Updater has been completely uninstalled.\"
