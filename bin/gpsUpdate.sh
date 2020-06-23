#!/bin/bash

## Modify gpsLat and gpsLon to your preferences. See the readme file for help

gpsLat="0.003"  #default value is 0.002, (1,108 ft LAT)
gpsLon="0.004"  #default value is 0.002, (1,215 ft LON)

########## DO NOT EDIT BELOW THIS LINE ##########
########## DO NOT EDIT BELOW THIS LINE ##########
########## DO NOT EDIT BELOW THIS LINE ##########

source /boot/adsb-config.txt

latA="$LATITUDE"
lonA="$LONGITUDE"

echo "Starting GPS position updater with a GPS coordinate precision of ${gpsLat}° latitude and ${gpsLon}° longitude." | ts
echo "Last known coodinates: $latA, $lonA" | ts

gpspipe -d -w -o /tmp/gpsDump

while [ -f /tmp/gpsDump ] ; do
  if grep -q 'lat\|lon\|alt' /tmp/gpsDump ; then
    LAT=$(cat /tmp/gpsDump | awk 'BEGIN{RS=","; FS=":"} /lat/ {save=$2} END {print save}')
    LON=$(cat /tmp/gpsDump | awk 'BEGIN{RS=","; FS=":"} /lon/ {save=$2} END {print save}')
    ALT=$(cat /tmp/gpsDump | awk 'BEGIN{RS=","; FS=":"} /alt/ {save=$2} END {print save}')
    ALT=$(echo "scale=0; $ALT * 3.281/1" | bc)
    latB=$(echo "scale=3; $LAT /1" | bc)
    lonB=$(echo "scale=3; $LON /1" | bc)
    latP=$(echo "define abs(i) {if (i < 0) return (-i); return (i)}; abs($latA - $latB) <= $gpsLat" | bc)
    lonP=$(echo "define abs(i) {if (i < 0) return (-i); return (i)}; abs($lonA - $lonB) <= $gpsLon" | bc)
    echo "$(tail -n 499 /home/pi/.gpsUpdate.log)" > /home/pi/.gpsUpdate.log

    if [ $latP -eq 1 ] && [ $lonP -eq 1 ] ; then
      echo "GPS Poisition $LAT, $LON is update to date!" | ts
      killall gpspipe
      rm /tmp/gpsDump
      # sleep 600 # systemd will restart the script after 600 secs (10 min)
      # gpspipe -d -w -o /tmp/gpsDump
      # echo "Checking current GPS position..." | ts

    elif [ $ALT -gt -1500 ] ; then
      echo "Updating LAT: ${LAT}°, LON: ${LON}°, ELEV: ${ALT}ft" | ts
      cat > /boot/adsb-config.txt <<- EOL
	LATITUDE=$LAT
	LONGITUDE=$LON
	ALTITUDE=${ALT}ft
	USER="$USER"
	DUMP1090=$DUMP1090
	GAIN=$GAIN
	DUMP978=$DUMP978
	EOL
      systemctl restart readsb
      systemctl restart adsbexchange-mlat.service
      latA=$latB
      lonA=$lonB
    fi
  fi
done
