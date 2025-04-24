#!/bin/bash

set -e
PROJECT_DIR="$(dirname "$0")"
INSTALL_PATH="/usr/local/bin"
AUTOSTART_PATH="/etc/xdg/autostart"
MENU_PATH="/usr/share/applications"
CONFIG_DIR="$HOME/.deb-updater"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# === Dependency Check ===
echo "[*] Checking required packages..."
REQUIRED_PKGS=(curl zenity yad mailutils gpg libnotify-bin)
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if (( ${#MISSING_PKGS[@]} )); then
    echo "[!] Installing missing packages: ${MISSING_PKGS[*]}"
    sudo apt install -y "${MISSING_PKGS[@]}"
fi

# === Install Main & Tray Scripts ===
echo "[*] Installing updater and tray launcher..."
sudo install -m 755 "$PROJECT_DIR/deb-updater.sh" "$INSTALL_PATH/deb-updater.sh"
sudo install -m 755 "$PROJECT_DIR/deb-updater-tray.sh" "$INSTALL_PATH/deb-updater-tray.sh"

# === Desktop Menu Shortcut ===
echo "[*] Creating desktop shortcut..."
sudo tee "$MENU_PATH/deb-updater.desktop" > /dev/null <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Deb Updater
Exec=$INSTALL_PATH/deb-updater.sh
Icon=system-software-update
Comment=Manually update .deb packages from GitHub
Categories=System;Utility;
Terminal=false
EOF

# === Run GUI & Email Config ===
"$PROJECT_DIR/gui-notifier-setup.sh"
"$PROJECT_DIR/email-config-setup.sh"

# === Create Autostart Entry ===
echo "[*] Setting up autostart..."
sudo tee "$AUTOSTART_PATH/deb-updater.desktop" > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Deb Updater
Exec=$INSTALL_PATH/deb-updater.sh
Icon=system-software-update
Comment=Automatically check and update .deb packages
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

# === AppArmor Notice ===
if [ -f /etc/apparmor.d/usr.bin.msmtp ]; then
    zenity --warning --text="⚠️ AppArmor may interfere with msmtp during setup. If prompted, DO NOT enable AppArmor support during mailutils setup."
fi

zenity --info --text="✅ Deb Updater installation complete. You can now launch it from your application menu."
echo "[✓] Installation complete."
