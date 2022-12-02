# Pi Camera Instructions
Everything is done on Raspberry Pi Zero.

## Installation
First, run `sudo apt-get install xrdp` to install xrdp.

Then, run `sudo apt-get install motion` to install motion.

## Configuration
Run `lsusb` and find the camera to make sure it is connected correctly.

Run `sudo vi /etc/default/motion` to open the motion configuration file, and change `start_motion_daemon` to yes.

Run `sudo vi /etc/motion/motion.conf` and configure the camera (what I did here is change 60 Hz to 24 Hz).

## Pre-flight Checks
Run the following three commands,
`mkdir /home/CamMonitor`
`sudo chgrp motion /home/CamMonitor`
`chmod g+rwx /home/CamMonitor`

## Recording
Run `sudo service motion start`.

The recorded video will be in the /home/CamMonitor file, and the camera is displaied on time on http://XXX.XXX.XXX.XXX:8081 (/XXX.XXX.XXX.XXX should be replaced by the IP address of Pi, and only IPV4 works).

