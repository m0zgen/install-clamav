#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Install ClamAV service to CentOS

# Install ClamAV
# ---------------------------------------------------\

Info() {
  printf "\033[1;32m$@\033[0m\n"
}

Warning()
{
  printf "\033[1;31m$@\033[0m\n"
}


if [[ -f /etc/clamd.d/scan.conf ]]; then
  Warning "ClamAV already installed!"
  exit 1
fi

yum install clamav clamav-update clamav-scanner-systemd -y

sleep 15

sed -i -e "s/^Example/#Example/" /etc/clamd.d/scan.conf
sed -i 's/.\(LocalSocket \/var\/run*.\)/\1/g' /etc/clamd.d/scan.conf
sed -i 's/.\(ExitOnOOM*.\)/\1/g' /etc/clamd.d/scan.conf

# Log settings
sed -i -e "s/#LogFile .*/LogFile \/var\/log\/clamd.scan/" /etc/clamd.d/scan.conf
sed -i -e "s/#LogFileMaxSize.*/LogFileMaxSize 0/" /etc/clamd.d/scan.conf
sed -i -e "s/#LogTime.*/LogTime yes/" /etc/clamd.d/scan.conf
sed -i -e "s/#LogSyslog.*/LogSyslog yes/" /etc/clamd.d/scan.conf
sed -i -e "s/#LocalSocket .*/LocalSocket \/run\/clamd.scan\/clamd.sock/" /etc/clamd.d/scan.conf

sed -i -e "s/#UpdateLogFile .*/UpdateLogFile \/var\/log\/freshclam.log/" /etc/freshclam.conf
sed -i -e "s/#LogFileMaxSize.*/LogFileMaxSize 0/" /etc/freshclam.conf
sed -i -e "s/#LogTime.*/LogTime yes/" /etc/freshclam.conf
sed -i -e "s/#LogSyslog.*/LogSyslog yes/" /etc/freshclam.conf

ln -s /etc/clamd.d/scan.conf /etc/clamd.conf

# SELinux
# ---------------------------------------------------\
setsebool -P antivirus_can_scan_system on
setsebool -P clamd_use_jit on

# Fix socket permissions
# ---------------------------------------------------\
mkdir /run/clamd.scan
chown clamscan:clamscan /run/clamd.scan/

# Logs
mkdir /var/log/clamav
chown clamscan:clamupdate /var/log/clamav/

touch /var/log/clamav/freshclam.log
chown clamupdate:clamupdate /var/log/clamav/freshclam.log

# Create daily update schedule for ClamAV
# ---------------------------------------------------\

if [[ -f /etc/cron.daily/freshclam ]]; then
  yes | rm -r /etc/cron.daily/freshclam
fi

cat >> /etc/cron.daily/freshclam <<_EOF_
#!/bin/bash
freshclam -v >> /var/log/clamav/freshclam.log
_EOF_

chmod 755 /etc/cron.daily/freshclam
chmod +x /etc/cron.daily/freshclam

# Install update service
# ---------------------------------------------------\
cat >> /usr/lib/systemd/system/freshclam.service <<_EOF_
# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target

[Service]
Type = forking
ExecStart = /usr/bin/freshclam -d -c 4
Restart = on-failure
PrivateTmp = true
# Reload service
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
_EOF_

# Update ClamAV
# ---------------------------------------------------\
if [[ -f /var/log/freshclam.log ]]; then
  yes | rm -r /var/log/freshclam.log
fi

freshclam -v

systemctl enable --now freshclam.service
sleep 10
systemctl enable --now clamd@scan.service

# Enable / Update logrotate
# ---------------------------------------------------\
cat > /etc/logrotate.d/clamd_scan <<_EOF_
/var/log/clamd.scan {
#  su clamscan clamupdate
    monthly
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    create 0660 clamscan clamscan
    postrotate
    /usr/bin/systemctl try-restart clamd@scan
    endscript
}
_EOF_

cat > /etc/logrotate.d/clamav-update <<_EOF_
/var/log/freshclam.log {
    monthly
    rotate 14
    notifempty
    missingok
    postrotate
    systemctl try-restart clamav-freshclam.service
    endscript
}
_EOF_

logrotate -v /etc/logrotate.d/clamd_scan
logrotate -v /etc/logrotate.d/clamav-update

# Done!
# ---------------------------------------------------\
systemctl status clamd@scan.service
systemctl status freshclam.service
Info "Done!"

echo -e "You will can check installed anti-virus with test virus files:"
Info "wget http://www.eicar.org/download/eicar.com && wget http://www.eicar.org/download/eicar_com.zip"