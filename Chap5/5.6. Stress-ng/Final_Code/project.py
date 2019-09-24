#!/usr/bin/env python
'''----------------------------------------------------------------------------------------------'''
'''
*Import libraries*
'''
from multiprocessing import Process, Queue
import multiprocessing
import subprocess
import threading
import os
import time as timep1
import time as timep2
import time as timeIOControl
    
'''----------------------------------------------------------------------------------------------'''
process_priority= 0
mathstress_worker= 0
memmorystress_worker= 0
networkstress_worker= 0
simulstress_worker= 0
boardtype = 0

'''----------------------------------------------------------------------------------------------'''
'''*Function to generate clock signal and output through hardware pin*'''
def defIOControl(process_priority,boardtype):
    '''*Init priority of the clock generation process*'''
    os.nice(process_priority)
    '''*Init Serial Port*'''
    if boardtype == 1:
        import serial
        ser = serial.Serial('/dev/ttyUSB0',9600)
    '''*Init GPIO*'''    
    if boardtype == 2:
        import RPi.GPIO as GPIO
        GPIO.setmode(GPIO.BOARD)
        GPIO.setwarnings(False)
        GPIO.setup(40, GPIO.OUT)
    elif boardtype == 3:
        import Adafruit_BBIO.GPIO as GPIO
        GPIO.setup("P8_7", GPIO.OUT)
    '''*Init Clock and make clock state to zeor level*'''
    timep2.sleep(1)
    start = timeIOControl.time()
    gpiostate = False
    end = timeIOControl.time()
    end = timeIOControl.time() + 0.01
    '''*Clock generation loop*'''
    while True:
        if timeIOControl.time() >= end:
            end = timeIOControl.time() + 0.01
            if boardtype == 1:
                ser.setRTS(gpiostate)
            if boardtype == 2:
                GPIO.output(40,gpiostate)
            elif boardtype == 3:
                GPIO.output("P8_7", gpiostate)
            gpiostate = not gpiostate
'''----------------------------------------------------------------------------------------------'''
'''*Function to Stress the system*'''
def defProcess1(mathstress,memmorystress,networkstress,simulstress):
    '''*Joining stress commands accordint to the user input*'''
    StressCommand = ["stress-ng"]
    if mathstress != 0:
        StressCommand.append("--vecmath")
        StressCommand.append(str(mathstress))
    if memmorystress != 0:
        StressCommand.append("--malloc")
        StressCommand.append(str(memmorystress))
    if networkstress != 0:
        StressCommand.append("--udp")
        StressCommand.append(str(networkstress))
    if simulstress != 0:
        StressCommand.append("--cpu")
        StressCommand.append(str(simulstress))
    timep1.sleep(2)
    '''*Runnig the stress command*'''
    subprocess.call(StressCommand)
    #subprocess.call(["stress-ng", "--stream", "3"])
    timep1.sleep(1)
'''----------------------------------------------------------------------------------------------'''
'''*Function to display System config*'''
def defprintconfig(boardtype,mathstress,memmorystress,networkstress,simulstress,process_priority):
    print "_________________________________________"
    print "----------***System Config***-----------"
    if boardtype == 1:
        print "Serial Port: Enabled"
        print "Clock Out Pin: Serial RTS"
    if boardtype == 2:
        print "Board: Raspberrey Pi"
        print "Clock Out Pin: GPIO PIN 40"
    if boardtype == 3:
        print "Board: Beagle Bone"
        print "Clock Out Pin: P8_7"
    else:
        print  "Board: No valid board selected"

    print "Clock generation Process Priority: ",process_priority
    print "-----------***Stress Workers***-----------"
    print "Mathematical Stress: ",mathstress
    print "Memory Stress:       ",memmorystress
    print "Network Stress:      ",networkstress
    print "Simultanious Stress: ",simulstress
    print "_________________________________________"
'''----------------------------------------------------------------------------------------------'''

def defreadinput():
    global process_priority
    global mathstress_worker
    global memmorystress_worker
    global networkstress_worker
    global simulstress_worker
    global boardtype
    '''*Loop for reading and validating board type*'''
    while True:
        print "_________________________________________"
        print "-----------***Board Type***-----------"
        print "0 No board Selected (Default)"
        print "1 Serial Port"
        print "2 Rabpberry Pi"
        print "3 Beable Bone Black"
        try:
            boardtype = input("Enter Board Type: ")
        except SyntaxError:
            print "*Enter Valid Board Type*"
            continue
        if boardtype > 0 and boardtype <= 3:
            break
        else:
            print "*Enter Valid Board Type*"
            continue
    '''*Loop for reading and validating priority level*'''
    while True:
        print "_________________________________________"
        print "-----------***Clock Genration Piority Level***-----------"
        print "-19 Highest Piority "
        print " 20 Lowest Priority"
        try:
            process_priority = input("Enter Priority Level(0 Default): ")
        except SyntaxError:
            process_priority = 0
        if process_priority >= -19 and process_priority <= 20:
            break
        else:
            print "*Enter Valid  Priority Level*"
            continue 
    '''*Loop for reading and validating stress workers*'''
    while True:
        print "_________________________________________"
        print "-----------***Workers to perform Stress to CPU***-----------"
        print "0 No stress"
        print "N Wrokers that perform stress operation(N must be greater than 1)"
        try:
            mathstress_worker = input("Enter Workers to perforem Math Stress(0 Default): ")
        except SyntaxError:
            mathstress_worker = 0
        if mathstress_worker >= 0:
            break
        else:
            print "*Enter Valid Number*"
            continue 
    '''*Loop for reading and validating stress workers*'''
    while True:
        print "_________________________________________"
        print "-----------***Workers to perform Stress to CPU***-----------"
        print "0 No stress"
        print "N Wrokers that perform stress operation(N must be greater than 1)"
        try:
            memmorystress_worker = input("Enter Workers to perforem Memmory Stress: ")
        except SyntaxError:
                memmorystress_worker = 0
        if memmorystress_worker >= 0:
            break
        else:
            print "*Enter Valid Number*"
            continue
    '''*Loop for reading and validating stress workers*'''
    while True:
        print "_________________________________________"
        print "-----------***Workers to perform Stress to CPU***-----------"
        print "0 No stress"
        print "N Wrokers that perform stress operation(N must be greater than 1)"
        try:
            networkstress_worker = input("Enter Workers to perforem Netowrk Stress: ")
        except SyntaxError:
                networkstress_worker = 0
        if networkstress_worker >= 0:
            break
        else:
            print "*Enter Valid Number*"
            continue 
    '''*Loop for reading and validating stress workers*'''
    while True:
        print "_________________________________________"
        print "-----------***Workers to perform Stress to CPU***-----------"
        print "0 No stress"
        print "N Wrokers that perform stress operation(N must be greater than 1)"
        try:
            simulstress_worker = input("Enter Workers to perforem Simultaneous Stress: ")
        except SyntaxError:
                simulstress_worker = 0
        if simulstress_worker >= 0:
            break
        else:
            print "*Enter Valid Number*"
            continue
    
'''----------------------------------------------------------------------------------------------'''
'''*Main loop*'''
if __name__ == '__main__':
    defreadinput();
    '''*Printing the system configuration*'''
    defprintconfig(boardtype,mathstress_worker,memmorystress_worker,networkstress_worker,simulstress_worker,process_priority)
    '''*Creating Process*'''
    process = Process(target=defIOControl,args=(process_priority,boardtype))
    process1 = Process(target=defProcess1,args=(mathstress_worker,memmorystress_worker,networkstress_worker,simulstress_worker))
    '''*Starting process*'''
    process.start()
    process1.start() 
    process.join()
    process1.join()
'''----------------------------------------------------------------------------------------------'''
