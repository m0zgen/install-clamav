#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Install daily ClamAV scan

# Envs /Functions
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

Info() {
  printf "\033[1;32m$@\033[0m\n"
}

# Install
# ---------------------------------------------------\
cp -u $SCRIPT_PATH/sheduler/clamscan-daily /etc/cron.daily/
chmod +x /etc/cron.daily/clamscan-daily

Info "Done!"
Info "Scheduler installed to /etc/cron.daily/ folder"

Info "You must change email receiver and sender in the /etc/cron.daily/clamscan-daily script!"