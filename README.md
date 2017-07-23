Grafical user interface (GUI) for solar cell characterization tool based on a Keithley 24XX sourcemeter
This project contains the GUI for https://github.com/EugenZimmermann/matlab-keithley-jv

Device/preference section is modular and can be extended by additional devices as relais (multiple cells measurements), shutter (automatic light/dark measurements), temperature controller (temperature dependent measurements), ... Module for automatic light intensity calibration is possible, if calibrated current of reference device is set in preferences.

Mandatory additional folders are:
- *Common* https://github.com/EugenZimmermann/matlab-common
- *CommonImpExp* https://github.com/EugenZimmermann/matlab-commonImpExp
- *CommonGUI* https://github.com/EugenZimmermann/matlab-commonGUI
- *CommonObjects* https://github.com/EugenZimmermann/matlab-commonObjects

![Main Window](ExamplePictures//mainwindow.png?raw=true "Main Window")

Tested: Matlab 2015b-2017a, Win7-10

Due to a significant change in graphics handling with Matlab 2014b this program is NOT COMPATIBLE TO MATLAB 2014a AND BELOW.

Author: Eugen Zimmermann, Konstanz, 2016 eugen.zimmermann [at] uni-konstanz [dot] de

Last Modified on 2017-07-23

ToDo:
- implement GUI Layout Toolbox for dynamic module implementation via preferences

Version 1.0
- initial release
