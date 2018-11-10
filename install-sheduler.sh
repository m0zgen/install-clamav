#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Install daily ClamAV scan

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Install
# ---------------------------------------------------\
cp $SCRIPT_PATH/sheduler/clamscan-daily /etc/cron.daily/
chmod +x /etc/cron.daily/clamscan-daily