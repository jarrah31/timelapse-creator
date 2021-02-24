# timelapse-creator
Create daily, weekly, monthly, or custom range time-lapses from a folder of images

This script has been designed to run on MacOS. Future versions will be modified to work on Linux as well.

It's primary purpose is to work with the excellent video surveillance software SecuritySpy for MacOS. https://www.bensoftware.com/securityspy/

## Prerequisites
Using Brew (https://brew.sh), installed the following packages:

`brew install ffmpeg coreutils gnu-getopt`

Run the following to add gnu-getopt to your PATH:

`echo 'export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"' >> ~/.zshrc`

Rename `video.newconf` `to video.conf` and edit the file to add your custom folder paths.


## Usage
```
Usage:
   dailytimelapse.sh [--debug] [-f <fps>] [-d <date>] | [-w <date>] | [-m <date>] | [-s <startdate>  -e <enddate>] -c <camname> [hv]

     -d YYYY-MM-DD : daily
     -w YYYY-MM-DD : weekly
     -m YYYY-MM    : monthly
     -s YYYY-MM-DD -e YYYY-MM-DD : start and end dates
     -c  : camera name (backcam gardencam hogcam)
     -f  : frames per second for the timelapse
     -h  : help
     -v  : verbose
-- debug : debug mode

Examples:

  Single Day Timelapse:
    dailytimelapse.sh -d 2021-01-10 -c camname

  Weekly Timelapse - specify any day within the required week. The following would be from Mon 18th Jan to Sun 24th Jan.
    dailytimelapse.sh -w 2021-01-22 -c camname

  Monthly Timelapse:
    dailytimelapse.sh -m 2020-11 -c camname

  Specify Custom Range Timelapse:
    dailytimelapse.sh -s 2020-11-15 -e 2020-11-25 -c camname

  Frames Per Second Defaults:
    Daily     - 10
    Weekly    - 15
    Montly    - 30

  FPS option -f <num> can be used with any timelapse range
    dailytimelapse.sh -f 20 -d 2021-01-10 -c camname
```
