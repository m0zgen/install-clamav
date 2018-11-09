#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Install daily ClamAV scan
# Copy ths file to /etc/cron.daily/
# Set executable - chmod +x /etc/cron.daily/clamscan-daily

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

#
# ---------------------------------------------------\
SUBJECT="`hostname` PASSED DAILY SCAN"
EMAIL="my@mail.ru"
LOG=/tmp/clamav.log
TMP_LOG=/tmp/clam.daily

av_report() {

    if [ `cat ${TMP_LOG}  | grep Infected | grep -v 0 | wc -l` != 0 ]
    then
  SUBJECT="[WARNING] `hostname` PASSED DAILY SCAN"
    fi

  EMAILMESSAGE=`mktemp /tmp/virus-alert.XXXXX`
    echo "To: ${EMAIL}" >>  ${EMAILMESSAGE}
    echo "From: clamalert@myserver.com" >>  ${EMAILMESSAGE}
    echo "Subject: ${SUBJECT}" >>  ${EMAILMESSAGE}
    echo "Importance: High" >> ${EMAILMESSAGE}
    echo "X-Priority: 1" >> ${EMAILMESSAGE}
    echo "`tail -n 50 ${TMP_LOG}`" >> ${EMAILMESSAGE}
    sendmail -t < ${EMAILMESSAGE}

  cat ${TMP_LOG} >> ${LOG}
  rm -rf ${TMP_LOG}
}

av_scan() {
  touch ${TMP_LOG}
  nice -n15 clamscan -r / --exclude-dir=/sys/ --quiet --infected --log=${TMP_LOG}
}

av_scan
av_report
