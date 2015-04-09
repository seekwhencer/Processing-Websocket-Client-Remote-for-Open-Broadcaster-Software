Processing Websocket Server and Client for Open Broadcaster Software Remote
==================================================

What is this?
--------------------------------------
- An App for [Processing](http://processing.org).
- Change a Source in OBS by Beat Detection.
- Control OBS via Web Client

Who benefits from it?
--------------------------------------
- In order to produce a Video Stream with more variety.
- have less or no intaraction to change the sources.
- have any cut on the beat!

What is needed?
--------------------------------------
### This Processing Sketch and the Web Client
[Download Master as Zip](https://github.com/seekwhencer/Processing-Websocket-Client-Remote-for-Open-Broadcaster-Software/archive/master.zip)

### Processing
1. [Processing](https://processing.org/download)
2. [Spacebrew Processing Library](https://github.com/Spacebrew/spacebrewP5) [download](https://github.com/Spacebrew/spacebrewP5/archive/master.zip)
3. [Napplet Processing Libary](https://github.com/acsmith/napplet) [download](https://github.com/acsmith/napplet/downloads)

### Open Broadcaster Software
1. [Open Broadcaster Software](https://obsproject.com/)
2. [OBS Remote Plugin](http://www.obsremote.com/download.html)

### Hardware
1. To have a HD Stream, you need to have a equal fast CPU to encode the final Stream.
2. For lower resolutions - lower machines satisfy.
3. For two ordinary USB2 Webcams (on Windows) you need one USB Controller. For more Webcams you need to use a second and third USB Controller. You can use a PCMCIA USB2 Controller for Laptops or PCI Express Card for Desktops.

What is todo?
--------------------------------------
1. Download and install the main programs.
2. Download the Processing Libraries and install them. But. How?
3. Download the Processing Sketch and Web Client and expand it somewhere on your Harddisk.
4. Open the Sketch: "beatsocket.pde" and run.

### How to install a Processing Library
- Download the Sources
- (Windows) On your Harddrive search the Folder: This folder contains the libraries are stored.
```bash
C:\Users\my_windows_username\Documents\processing\libraries"
```
- Replace "my_windows_username" with your Windows Username.
- Copy the Sources in this Folder so that these Folder are existing:
```bash
C:\Users\my_windows_username\Documents\processing\libraries\library_name\library\library_package.jar"
```
- Do it for two Times, for every Processing Library. "library_name" and "library_package.jar" are various.
- Now run Processing again.
- Now existing these Folder:
```bash
C:\Users\my_windows_username\Documents\processing\libraries\spacebrew\library\json4processing.jar"
C:\Users\my_windows_username\Documents\processing\libraries\spacebrew\library\Websocket.jar"
C:\Users\my_windows_username\Documents\processing\libraries\spacebrew\library\spacebrew.jar"
C:\Users\my_windows_username\Documents\processing\libraries\napplet\library\napplet.jar"
```