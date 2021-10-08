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

ln -s /etc/clamd.d/scan.conf /etc/clamd.conf

# SELinux
# ---------------------------------------------------\
setsebool -P antivirus_can_scan_system on
setsebool -P clamd_use_jit on

# Update ClamAV
# ---------------------------------------------------\
freshclam -v

# Enable and start ClamAV
# ---------------------------------------------------\
systemctl start clamd@scan
systemctl enable clamd@scan

# Create daily update schedule for ClamAV
# ---------------------------------------------------\

if [[ -f /etc/cron.daily/freshclam ]]; then
  yes | rm -r /etc/cron.daily/freshclam
fi

cat >> /etc/cron.daily/freshclam <<_EOF_
#!/bin/bash
freshclam -v >> /var/log/freshclam.log
_EOF_

chmod 755 /etc/cron.daily/freshclam
chmod +x /etc/cron.daily/freshclam

# Install update service
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

[Install]
WantedBy=multi-user.target
_EOF_

systemctl enable freshclam.service
systemctl start freshclam.service

# Done!
# ---------------------------------------------------\
systemctl status clamd@scan
systemctl status freshclam.service
Info "Done!"

echo -e "You will can check installed anti-virus with test virus files:"
Info "wget http://www.eicar.org/download/eicar.com && wget http://www.eicar.org/download/eicar_com.zip"