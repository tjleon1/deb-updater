#!/bin/bash

yad --notification \
  --image=system-software-update \
  --text="Deb Updater" \
  --command="/usr/local/bin/deb-updater.sh"
