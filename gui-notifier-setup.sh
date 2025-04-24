#!/bin/bash

CONFIG_DIR="$HOME/.deb-updater"
GUI_PREFS="$CONFIG_DIR/gui-settings.ini"
mkdir -p "$CONFIG_DIR"

# === Load previous GUI settings if they exist ===
if [[ -f "$GUI_PREFS" ]]; then
    source "$GUI_PREFS"
fi

# === Prompt for GUI-related settings ===
FORM_OUTPUT=$(zenity --forms \
    --title="Deb Updater Notifications" \
    --text="Choose your preferred notification types:" \
    --separator="|" \
    --add-combo="Enable GUI popups?" --combo-values="Yes|No" \
    --add-combo="Enable fail-safe fallbacks?" --combo-values="Yes|No" \
    --add-combo="Enable system tray launcher?" --combo-values="Yes|No")

GUI_POPUP=$(echo "$FORM_OUTPUT" | cut -d '|' -f1)
FAIL_SAFE=$(echo "$FORM_OUTPUT" | cut -d '|' -f2)
ENABLE_TRAY=$(echo "$FORM_OUTPUT" | cut -d '|' -f3)

# === Save settings ===
echo "GUI_POPUP=$GUI_POPUP" > "$GUI_PREFS"
echo "FAIL_SAFE=$FAIL_SAFE" >> "$GUI_PREFS"
echo "ENABLE_TRAY=$ENABLE_TRAY" >> "$GUI_PREFS"

# === Optional Tray Setup ===
if [[ "$ENABLE_TRAY" == "Yes" ]]; then
    if [[ ! -f /usr/local/bin/deb-updater-tray.sh ]]; then
        sudo tee /usr/local/bin/deb-updater-tray.sh > /dev/null <<EOF
#!/bin/bash
yad --notification --image=system-software-update --text="Deb Updater" --command="/usr/local/bin/deb-updater.sh"
EOF
        sudo chmod +x /usr/local/bin/deb-updater-tray.sh
    fi

    mkdir -p "$HOME/.config/autostart"
    tee "$HOME/.config/autostart/deb-updater-tray.desktop" > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Deb Updater Tray
Exec=/usr/local/bin/deb-updater-tray.sh
Icon=system-software-update
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

    zenity --info --text="✅ Tray launcher installed and will start on login."
else
    rm -f "$HOME/.config/autostart/deb-updater-tray.desktop"
    zenity --info --text="ℹ️ Tray launcher will not autostart. You can launch it manually later if needed."
fi
