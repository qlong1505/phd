# My PhD's code and script
This github contain my code, script and simulation files which were used in my PhD at RMIT University (07/2015-09/2019).
Please read the document in "doc" directory for more detail.

# Chapter 3

## Delay variable design on MATLAB and Ltspice

Software to run:

- [MATLAB](https://au.mathworks.com/downloads/web_downloads/) 2017b or later. Run **variable\_delay.slx** file then run **plot.m** file to plot the output figure
- [Ltspice](https://www.analog.com/en/design-center/design-tools-and-calculators/ltspice-simulator.html): open _\*.asc_ files

## DC Motor controller

Model files includes

- MATLAB script
- Simulink file to model the motor controller
- Step to run:
  - ◦◦Install library in lib folder. Instruction can be found [here](https://au.mathworks.com/help/simulink/ug/adding-libraries-to-the-library-browser.html)
  - ◦◦Run the script **motor\_PI\_Controller.m**
  - ◦◦Run Simulink file **Motor\_Model\_full.slx**
  - ◦◦Plot output response by run &quot; **Plot\_output\_response.m**&quot;. This script can be modify to choose task jitter pattern to display

Hardware implementation

- Read the instruction part at the beginning of the file **OUSB\_motor\_PI\_controller.c**
- [OUSB Board document](https://pjradcliffe.wordpress.com/open-usb-io/resources/)
- [Motor hardware](https://www.futurlec.com/Mini_DC_Motor.shtml)

# Chapter 4

Code for running the envelop responses.

The step to run the script is describe in file **&quot;script.m&quot;** and **&quot;script\_20180930.m&quot;**

# Chapter 5

## Task jitter measurement

- Arduino file code for measure task jitter : **task-jitter-measurement.ino**
- Python code to save data from Arduino to csv file on PC: **&quot;serial3.py&quot;**

## Stress-ng python code

This stress function is written in Python and should be run on target platform such as Orange Pi or BeagleBone black

## MATLAB code and scripts.

MATLAB scripts for experiment in section 5.6
