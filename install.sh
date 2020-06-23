#!/bin/bash

if [ -f /etc/default/gpsd ] ; then # GPSD must be installed for this script/service to work
  source /etc/default/gpsd
else
  echo "GPSD is missing. Please install and configure GPSD for use with your GPS before installing gpsUpdater."
  echo "Installation Aborted!"
  exit
fi
if [ -z $DEVICES ] ; then # A GPS device must be configured for this script/service to work
  echo "Your GPS device has not been specifed in /etc/default/gpsd. Please edit, then retry installation."
  echo "Installation Aborted!"
  exit
fi
if [ -f /boot/adsb-config.txt ] ; then # This script checks to make sure the ADSBx config file is present,
                                       # since it has only been tested with the ADSBx Buster image
  if [ "$(command -v awk | wc -l)" -eq 0 ] ; then # Installing required packages if missing
        apt install gawk -y
  fi
  if [ "$(command -v bc | wc -l)" -eq 0 ] ; then # Installing required packages if missing
    apt install bc -y
  fi
  if [ "$(command -v gpspipe | wc -l)" -eq 0 ] ; then # Installing required packages if missing
    apt install gpsd-clients -y
  fi
  if [ "$(command -v ts | wc -l)" -eq 0 ] ; then # Installing required packages if missing
    apt install moreutils -y
  fi

  cp ./bin/gpsUpdate.sh /usr/local/bin
  cp ./systemd/gpsUpdate.service /lib/systemd/system

  systemctl enable gpsUpdate
  systemctl start gpsUpdate

  echo "gpsUpdate service installed successfully"
else
  echo "The config file 'adsb-config.txt' is missing from /boot."
  echo "Installation Aborted!"
fi
