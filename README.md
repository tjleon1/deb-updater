# 🧩 Deb Updater

A modern GUI-based update manager for manually installed `.deb` applications.  
Fetches the latest versions from GitHub, compares them, installs updates, and optionally sends email alerts.

Includes:

- 🛎️ System tray icon for quick access  
- 🔁 Autostart on user login  
- 🧠 Persistent per-user configuration  
- 📨 Email notifications  
- 💡 Fallback to AppImage if `.deb` not available  

## ✨ Features

- ✅ Auto-updates for GitHub-hosted `.deb` packages  
- 📨 Optional email alerts and update summaries  
- 🛎️ Tray icon (via `yad`) for manual activation  
- 🔁 Autostarts at login for all users  
- 🧠 Remembers email preferences per user  
- 💡 Works with `.deb` and `.AppImage` formats  

## 📦 Dependencies

The installer **auto-checks and installs** required packages:

- `curl`  
- `zenity`  
- `yad`  
- `mailutils`  
- `libnotify-bin` (`notify-send`)  
- `gpg` (for encrypted Gmail app passwords)

## 🚀 Installation

Run the installer script:

```bash
chmod +x install-deb-updater.sh
./install-deb-updater.sh
```

This will:

- Copy system-wide scripts to `/usr/local/bin/`  
- Register tray and autostart launchers  
- Add the updater to your system menu  

## 📤 Email Configuration

First-time launch or `sudo` run will prompt for:

- 📧 Email address for notifications  
- ✅ Whether to enable email alerts  

Settings are saved to:

```bash
~/.deb-updater/config.ini
```

Encrypted Gmail app passwords can be stored securely using `gpg`.

## 🧹 Uninstall

```bash
sudo ./uninstall-deb-updater.sh
```

This will:

- Remove all installed scripts and launchers  
- Prompt to delete personal configuration files  

## 📁 Project Structure

| Path                                             | Purpose                            |
|--------------------------------------------------|------------------------------------|
| `/usr/local/bin/deb-updater.sh`                 | Main update script                 |
| `/usr/local/bin/deb-updater-tray.sh`            | Tray icon launcher                 |
| `/etc/xdg/autostart/deb-updater.desktop`        | Autostart GUI on login             |
| `/etc/xdg/autostart/deb-updater-tray.desktop`   | Autostart tray icon on login       |
| `/usr/share/applications/deb-updater.desktop`   | Desktop menu entry                 |
| `~/.deb-updater/`                               | User configuration, logs, cache    |

## 🛰️ Roadmap

- 🔍 Auto-discovery of all manually installed `.deb` apps  
- 🛎️ Tray icon update notifications  
- 🔐 GitHub token support for private repo updates  
- 📜 Interactive changelogs before installation  

## 👤 Author & License

Created by **Tim Leon**  
Licensed under the **MIT License**
