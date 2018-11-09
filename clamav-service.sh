#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Install ClamAV service to CentOS


yum install clamav clamav-update clamav-scanner-systemd -y

ln -s /etc/clamd.d/scan.conf /etc/clamd.conf

setsebool -P antivirus_can_scan_system on
setsebool -P clamd_use_jit on

sed -i -e "s/^Example/#Example/" /etc/clamd.d/scan.conf
sed -i 's/.\(LocalSocket \/var\/run*.\)/\1/g' /etc/clamd.d/scan.conf
sed -i 's/.\(ExitOnOOM*.\)/\1/g' /etc/clamd.d/scan.conf

freshclam -v

systemctl start clamd@scan
systemctl enable clamd@scan


cat >> /etc/cron.daily/freshclam <<_EOF_
#!/bin/bash
freshclam -v >> /var/log/freshclam.log
_EOF_

chmod 755 /etc/cron.daily/freshclam