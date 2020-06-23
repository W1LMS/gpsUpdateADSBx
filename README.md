[![Build Status](https://travis-ci.org/kn1gh7h4wk/gpsUpdate.svg?branch=master)](https://travis-ci.org/kn1gh7h4wk/gpsUpdate)

I created this script for personal use, but have made it available to the public, as well as contributors, for all who may find it useful or may improve upon it. I am not a coder or programmer so the script may look rough around the edges. I'm more of a hobbyist.

This script was designed to work with [ADS-B Exchange's Raspberry Pi image: ADSBx Buster](https://www.adsbexchange.com/how-to-feed/adsbx-custom-pi-image/). I have a portable unit that I take with me and I wanted the Raspberry Pi to figure out where it was and update itself. Once the Raspberry Pi is running on said image, properly configured with required packages installed and GPS module, the script can be installed.

#### HOW DOES IT WORK?

The script runs as a service that cycles every 10 min, once the initial GPS fix is made. It uses [awk](http://manpages.ubuntu.com/manpages/bionic/man1/awk.1plan9.html) to retrieve the latitude, longitude and elevation from [gpspipe](http://manpages.ubuntu.com/manpages/trusty/man1/gpspipe.1.html). It then rounds the elevation to the nearest whole decimal. Next, it uses the values of `gpsLon` and `gpsLat` to calculate your current position with the previous position to see if it needs to update your location. If it needs to update, it will create a new config file for ADSBx and restart the services. If no update is needed, it will sleep for 10 minutes and check again.

#### PRE-REQUISITES

The required packages for this script are: [gpsd](https://manpages.debian.org/buster/gpsd/gpsd.8.en.html), [gpsd-clients](https://manpages.debian.org/buster/gpsd-clients/index.html) (for [gpspipe](https://manpages.debian.org/buster/gpsd-clients/gpspipe.1.en.html)), and [bc](https://manpages.debian.org/buster/bc/bc.1.en.html). The packages [gawk](https://manpages.debian.org/buster/gawk/gawk.1.en.html) and [moreutils](https://manpages.debian.org/buster/moreutils/index.html) (for [ts](https://manpages.debian.org/buster/moreutils/ts.1.en.html)) are pre-installed by default in the ADSBx Buster image.

    $ sudo apt install gpsd gpsd-clients bc

After installing the required packages and their dependencies, you'll need to tell `gpsd` where your GPS device is located. If you are using a USB dongle GPS, like the U-blox7, it should be located at `/dev/ttyACM0`. If you are using a GPS hat, then your location will be either `/dev/ttyAMA0` or `/dev/ttyS0`, depending on your boot config settings, specifically UART.

You will need to edit `/etc/default/gpsd` and change `DEVICES=""` to `DEVICES="/dev/ttyACM0"`, or if using a GPS hat, the location of your hat. If you are not sure where your GPS hat is located, check to see which device is receiving data by using cat on both devices: 

    $ cat /dev/ttyAMA0
    
or
    
    $ cat /dev/ttyS0

Your GPS will need to have a fix for this to work, so you will want to be near a window or outside. Check your GPS manual for the light pattern that indicates a GPS fix. If you see lines of data filling your screen, then you have located the right device. Each line will start with "$GPxxx". Next, find `GPSD_OPTIONS=""` and change to `GPSD_OPTIONS="-n"`. This tells `gpsd` not to wait for the client to connect before polling.

Your file should look something like this when done:

    # Default settings for the gpsd init script and the hotplug wrapper.

    # Start the gpsd daemon automatically at boot time
    START_DAEMON="true"

    # Use USB hotplugging to add new USB devices automatically to the daemon
    USBAUTO="true"

    # Devices gpsd should collect to at boot time.
    # They need to be read/writeable, either by user gpsd or the group dialout.
    DEVICES="/dev/ttyACM0"

    # Other options you want to pass to gpsd
    GPSD_OPTIONS="-n"

#### THE SCRIPT

At the top of the script, you'll want to edit the 2 variables to specify when the script will update the ADSBx if your location moves (`gpsLat` & `gpsLon`). This setting will vary depending on where you are in the world (mid-latitude vs high-latitudes). Every 10 minutes, the script checks your current position with your last saved position. At its default setting, it will update your location if you move more than 0.003 decimal degrees latitude and 0.004 decimal degrees longitude. You can use the latitude/longitude calculator [here](http://www.meridianoutpost.com/resources/etools/calculators/calculator-latitude-longitude-distance.php) to find the optimum setting for your part of the world. I live at the 34° latitude, so I am using the following settings to get my Pi to update if I move somewhere around 1,000~1,600 ft:

    Sample data

        gpsLat="0.003" #approx. 1,108 ft
        gpsLon="0.004" #approx. 1,215 ft
        #Diagonally, this is approx. 1,637 ft
        
I will be making updates to this script, so if you find this useful, please check back often for updates.

#### INSTALLATION

    $ sudo ./install.sh

In the parent folder, there is a installation script (`install.sh`) that will check to make sure the require packages are installed, that a GPS device is configured, and that you are using the ADSBx Buster image. Then it places `gpsUpdate.sh` in `/usr/bin` and `gpsUpdate.service` in  `/lib/systemd/system`. Lastly, it starts and enables the service. Voila! Your Raspberry Pi ADS-B Receiver should now self update it's GPS when ever you move more than a few fractions of decimal degrees (depending on your settings).
