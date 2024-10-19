#!/bin/bash

# verify root
if [ "${EUID}" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# load DietPi image on to eMMC/SSD
apt-get install -y xz-utils
xz -dc DietPi*.img.xz | dd of=/dev/mmcblk1 status=progress

# mount eMMC/SSD
mkdir -p /mnt/sd
mount /dev/mmcblk1p1 /mnt/sd

# load configuration settings
sed -i 's/AUTO_SETUP_LOCALE=.*/AUTO_SETUP_LOCALE=en_US.UTF-8/' /mnt/sd/boot/dietpi.txt
sed -i 's/AUTO_SETUP_KEYBOARD_LAYOUT=.*/AUTO_SETUP_KEYBOARD_LAYOUT=us/' /mnt/sd/boot/dietpi.txt
sed -i 's/AUTO_SETUP_TIMEZONE=.*/AUTO_SETUP_TIMEZONE=America\/New_York/' /mnt/sd/boot/dietpi.txt
sed -i 's/AUTO_SETUP_NET_WIFI_COUNTRY_CODE=.*/AUTO_SETUP_NET_WIFI_COUNTRY_CODE=US/' /mnt/sd/boot/dietpi.txt
sed -i 's/AUTO_SETUP_NET_HOSTNAME=.*/AUTO_SETUP_NET_HOSTNAME=fltr/' /mnt/sd/boot/dietpi.txt
sed -i 's/AUTO_SETUP_RAMLOG_MAXSIZE=.*/AUTO_SETUP_RAMLOG_MAXSIZE=200/' /mnt/sd/boot/dietpi.txt
sed -i 's/AUTO_SETUP_BROWSER_INDEX=.*/AUTO_SETUP_BROWSER_INDEX=0/' /mnt/sd/boot/dietpi.txt
sed -i 's/SURVEY_OPTED_IN=.*/SURVEY_OPTED_IN=0/' /mnt/sd/boot/dietpi.txt
sed -i 's/CONFIG_CHECK_APT_UPDATES=.*/CONFIG_CHECK_APT_UPDATES=2/' /mnt/sd/boot/dietpi.txt
sed -i 's/CONFIG_SERIAL_CONSOLE_ENABLE=.*/CONFIG_SERIAL_CONSOLE_ENABLE=0/' /mnt/sd/boot/dietpi.txt
sed -i 's/CONFIG_ENABLE_IPV6=.*/CONFIG_ENABLE_IPV6=0/' /mnt/sd/boot/dietpi.txt

# TODO
#sed -i 's/AUTO_SETUP_CUSTOM_SCRIPT_EXEC=.*/AUTO_SETUP_CUSTOM_SCRIPT_EXEC=https--path--to--Automation_Custom_Script.sh--TODO/' /mnt/sd/boot/dietpi.txt
#sed -i 's/#AUTO_SETUP_SSH_PUBKEY=.*/AUTO_SETUP_SSH_PUBKEY=your--ssh--key--TODO/' /mnt/sd/boot/dietpi.txt
#sed -i 's/SOFTWARE_DISABLE_SSH_PASSWORD_LOGINS=.*/SOFTWARE_DISABLE_SSH_PASSWORD_LOGINS=1/' /mnt/sd/boot/dietpi.txt
#sed -i 's/AUTO_SETUP_AUTOMATED=.*/AUTO_SETUP_AUTOMATED=1/' /mnt/sd/boot/dietpi.txt
#sed -i 's/AUTO_SETUP_GLOBAL_PASSWORD=.*/AUTO_SETUP_GLOBAL_PASSWORD=Password-Login-Is-Disabled/' /mnt/sd/boot/dietpi.txt

umount /mnt/sd

shutdown now

exit
