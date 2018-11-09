#!/bin/bash
# Created by Yevgeniy Goncharov, https://sys-adm.in
# Install ClamAV service to CentOS

# Install ClamAV
# ---------------------------------------------------\
yum install clamav clamav-update clamav-scanner-systemd -y

# On Fedora file exist, on CentOS file does not exist
# ---------------------------------------------------\
FILE="/etc/clamd.conf"

if [ -f $FILE ]; then
  echo "$FILE exists..."
  # sed -i 's/#Example.*/Example/' /etc/clamd.d/scan.conf
  # sed -i 's/#LocalSocket \/var.*/LocalSocket \/var\/run\/clamd.scan\/clamd.sock/' /etc/clamd.d/scan.conf
  # sed -i 's/#ExitOnOOM.*/ExitOnOOM yes/' /etc/clamd.d/scan.conf

  sed -i -e "s/^Example/#Example/" /etc/clamd.d/scan.conf
  sed -i 's/.\(LocalSocket \/var\/run*.\)/\1/g' /etc/clamd.d/scan.conf
  sed -i 's/.\(ExitOnOOM*.\)/\1/g' /etc/clamd.d/scan.conf
else
   echo "$FILE does not exist..."
cat >> /etc/clamd.conf <<_EOF_
LogSyslog yes
LocalSocket /var/run/clamd.scan/clamd.sock
User clamscan
ExitOnOOM yes
_EOF_
fi

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
cat >> /etc/cron.daily/freshclam <<_EOF_
#!/bin/bash
freshclam -v >> /var/log/freshclam.log
_EOF_

chmod 755 /etc/cron.daily/freshclam

# Done!
# ---------------------------------------------------\
systemctl status clamd@scan
echo -e "Done!"