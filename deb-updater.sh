#!/bin/bash

# === Configuration ===
SCRIPT_NAME="deb-updater"
CONFIG_DIR="$HOME/.deb-updater"
CONFIG_FILE="$CONFIG_DIR/config.ini"
DOWNLOAD_DIR="$CONFIG_DIR/downloads"
LOG_DIR="$CONFIG_DIR/logs"
EMAIL_LOG="$LOG_DIR/email.log"
LOG_FILE="$LOG_DIR/update.log"
EMAIL_ENABLED=false
EMAIL_RECIPIENT=""
GPG_KEY_ID="$(gpg --list-keys --with-colons | grep '^pub' | cut -d ':' -f5 | head -n1)"

mkdir -p "$DOWNLOAD_DIR" "$LOG_DIR"

# === Load or prompt config ===
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    EMAIL_ENABLED=false
    EMAIL_RECIPIENT=""
fi

if [[ "$EUID" -eq 0 || ! -f "$CONFIG_FILE" ]]; then
    FORM_OUTPUT=$(zenity --forms \
        --title=".deb App Updater" \
        --text="Set notification options (only shown for root or first run):" \
        --separator="|" \
        --add-entry="Email (optional)" \
        --add-combo="Send Email Notification" \
        --combo-values="Yes|No")

    EMAIL_RECIPIENT=$(echo "$FORM_OUTPUT" | cut -d '|' -f1)
    EMAIL_OPTION=$(echo "$FORM_OUTPUT" | cut -d '|' -f2)

    if [[ "$EMAIL_OPTION" == "Yes" && -n "$EMAIL_RECIPIENT" ]]; then
        EMAIL_ENABLED=true
    else
        EMAIL_ENABLED=false
    fi

    echo "EMAIL_RECIPIENT=\"$EMAIL_RECIPIENT\"" > "$CONFIG_FILE"
    echo "EMAIL_ENABLED=$EMAIL_ENABLED" >> "$CONFIG_FILE"
fi

# === Required Commands ===
require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[!] Installing missing command: $1" | tee -a "$LOG_FILE"
        sudo apt install -y "$2" || zenity --error --title="Install Failed" --text="Could not install required package: $2"
    fi
}

require_command curl curl
require_command notify-send libnotify-bin
require_command zenity zenity
require_command mail mailutils

# === Test Email (only on GUI setup or config update) ===
if [[ "$EUID" -eq 0 || ! -f "$EMAIL_LOG" ]]; then
    if [ "$EMAIL_ENABLED" = true ]; then
        ( 
            echo -e "The .deb updater script is configured and ready to send updates." | 
            mail -s "✅ Deb Updater Email Test" "$EMAIL_RECIPIENT"
        ) && {
            echo "[Email Sent] Deb Updater Test: $EMAIL_RECIPIENT" >> "$EMAIL_LOG"
            zenity --info --title="Email Sent" --text="✅ Test email sent to $EMAIL_RECIPIENT"
        } || {
            zenity --error --title="Email Failed" --text="❌ Failed to send test email to $EMAIL_RECIPIENT"
            echo "[Email Error] Could not send test email to $EMAIL_RECIPIENT" >> "$EMAIL_LOG"
        }
    fi
fi

# === Helper Functions ===
notify() {
    notify-send "$1" "$2"
    if [ "$EMAIL_ENABLED" = true ]; then
        echo -e "$2" | mail -s "$1" "$EMAIL_RECIPIENT" && echo "[Email Sent] $1: $EMAIL_RECIPIENT" >> "$EMAIL_LOG" || {
            zenity --error --title="Email Failed" --text="❌ Failed to send email for: $1"
            echo "[Email Error] Failed to send email for: $1" >> "$EMAIL_LOG"
        }
    fi
}

gui_error() {
    zenity --error --title="$1" --text="$2"
    if [ "$EMAIL_ENABLED" = true ]; then
        echo -e "$2" | mail -s "$1" "$EMAIL_RECIPIENT" && echo "[Email Sent] $1: $EMAIL_RECIPIENT" >> "$EMAIL_LOG" || {
            zenity --error --title="Email Failed" --text="❌ Failed to send email for: $1"
            echo "[Email Error] Failed to send email for: $1" >> "$EMAIL_LOG"
        }
    fi
}

download_and_install() {
    APP_NAME=$1
    INSTALLED=$2
    REPO=$3
    MATCH_PATTERN=$4
    FALLBACK_URL=$5  # optional fallback URL

    echo "[*] Checking $APP_NAME..." >> "$LOG_FILE"
    JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
    LATEST=$(echo "$JSON" | grep '"tag_name":' | head -n1 | cut -d '"' -f4 | tr -d 'v')

    if [ "$INSTALLED" != "$LATEST" ] && [ -n "$LATEST" ]; then
        echo "[$APP_NAME] Update available: $INSTALLED → $LATEST" >> "$LOG_FILE"

        ASSET_URL=$(echo "$JSON" | grep "browser_download_url" | grep "$MATCH_PATTERN" | cut -d '"' -f4 | head -n1)

        if [ -z "$ASSET_URL" ] && [ -n "$FALLBACK_URL" ]; then
            echo "[$APP_NAME] Using fallback URL" >> "$LOG_FILE"
            ASSET_URL="$FALLBACK_URL"
        fi

        if [ -z "$ASSET_URL" ]; then
            echo "[$APP_NAME] .deb or AppImage asset not found!" | tee -a "$LOG_FILE"
            gui_error "$APP_NAME Update Failed" "Could not find a valid installer for $APP_NAME"
            return
        fi

        FILENAME=$(basename "$ASSET_URL")
        FILEPATH="$DOWNLOAD_DIR/$FILENAME"

        echo "Downloading: $FILENAME" >> "$LOG_FILE"
        curl -L "$ASSET_URL" -o "$FILEPATH" || {
            gui_error "$APP_NAME Download Failed" "Could not download $FILENAME"
            echo "[$APP_NAME] Download failed" >> "$LOG_FILE"
            return
        }

        echo "Installing: $FILENAME" >> "$LOG_FILE"
        if [[ "$FILENAME" == *.deb ]]; then
            sudo apt install -y "$FILEPATH" || {
                gui_error "$APP_NAME Install Failed" "Could not install $FILEPATH"
                echo "[$APP_NAME] Install failed" >> "$LOG_FILE"
                return
            }
        else
            chmod +x "$FILEPATH"
            notify "$APP_NAME Ready" "AppImage downloaded: $FILEPATH (manual launch required)"
        fi

        notify "$APP_NAME Updated" "$INSTALLED → $LATEST"
    else
        echo "[$APP_NAME] Up to date: $INSTALLED" >> "$LOG_FILE"
    fi
}

# === Supported Apps ===
download_and_install "RustDesk" "$(dpkg -s rustdesk 2>/dev/null | grep '^Version:' | awk '{print $2}')" "rustdesk/rustdesk" "amd64.deb" ""
download_and_install "Balena Etcher" "$(dpkg -s balena-etcher 2>/dev/null | grep '^Version:' | awk '{print $2}')" "balena-io/etcher" "amd64.deb" ""
download_and_install "Bitwarden" "$(dpkg -s bitwarden 2>/dev/null | grep '^Version:' | awk '{print $2}')" "bitwarden/desktop" "amd64.deb" "https://vault.bitwarden.com/download/?app=desktop&platform=linux"
download_and_install "Docker Desktop" "$(dpkg -s docker-desktop 2>/dev/null | grep '^Version:' | awk '{print $2}')" "docker/desktop" "linux.*amd64.deb" ""
download_and_install "RPi Imager" "$(dpkg -s rpi-imager 2>/dev/null | grep '^Version:' | awk '{print $2}')" "raspberrypi/rpi-imager" "amd64.deb" "https://downloads.raspberrypi.org/imager/imager_latest_amd64.deb"
download_and_install "IPScan" "$(dpkg -s ipscan 2>/dev/null | grep '^Version:' | awk '{print $2}')" "angryip/ipscan" "amd64.deb" ""
download_and_install "STL Thumb" "$(dpkg -s stl-thumb 2>/dev/null | grep '^Version:' | awk '{print $2}')" "sdurand/stl-thumb" "amd64.deb" ""

# === Clean Up Old Files ===
find "$DOWNLOAD_DIR" -type f -name "*.deb" -mtime +2 -delete

echo "✅ Update check complete." | tee -a "$LOG_FILE"
notify "Deb Updater" "All checks completed."
echo "Deb Updater running..."

