
/*
 RMIT University
 Motor Controller update
 V16.10.04:
        - PI controller
        - jitter option for sampling
 
 V16.09.16:
  - Add controller loop
 
 V16.09.04:
  
  - loop controller 10ms
  - Take sample when there are both rising and falling edge of flipflop
  
 V16.08.20:
  - new 200us interrupt function ( to replace 500us)
  - recorded 200 value of speed
 
 
 
 */

/*------------------ my_code -------------------------------------------------

PURPOSE : This project does a lot of hardware control using an
          Arduino style library for the ATMEGA32 on the 
          Open-USB-IO board.  It also integrates the CoUSB code
          so you can debug using just the USB link.
          
          See the document arduino_ousb.pdf for a brief description
          of the functions and what they can do.
          See section 7.3 of the main OUSB manual (on the desktop)
          and see code in /home/user/projects/co-USB/_main_demo_of_CoUSB/
          to see what is possible using CoUSB.
          

TO COMPILE AND PROGRAM the Open-USB_IO BOARD
  - Type "make all" to ensure everything is compiled.
  - Plug an Open-USB-IO board into a USB port.
  - If the USB Bootloader is installed then move the link on J10
    near the LEDs to J9 near the trim pot.  Hit reset on the board
    then type "make usbprog".  Now move the link on J9 back to J10.
    If you are using the STK-200 programming cable from
    a parallel port to the ISP header on Open-USB-IO then
    type "make prog".
  - Look at the code to see what the program can do.
    Change the indicated switches to see LEDs rotate and more.
  - You will probably want to re-install the USB interface program
    after you finish with this code.
    To restore with the USB bootloader move the link from J10 to J9,
    hit reset, the type "ousb_usbprog".  Return the link from J9 to
    J10.  Try a simple command such as "ousb io portb 255" to check
    the USB interface program is working.
    To achieve the same using the STK-200 cable type
      ousb_prog


ALSO
  - In the terminal type "make help" to see all the make file can do.
    
    
    
NOTE: the Arduino libraries are easy to use but they are slow and 
      generate extra code.  If you need speed then work directly
      with the registers,  see the code in 
      /home/user/projects/AAA_simple_ousb_projects and 
      /home/user/projects/co-USB/_main_demo_of_CoUSB/
      for some examples.
*/

//--------------- HEADER FILES------------------------------------------------
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#include <stdio.h> // needed for printf, adds a lot of code.
#include "../../co-USB/usbdrv/main.h"
#include "/home/user/projects/arduino/arduino_libraries/Arduino.h"

//=============== user constants and variables ==================================

//volatile uint16_t counter ; // view this with the command "ousb symr -u08 counter"
// volatile is needed to ensure the variable is visible
// to any debugger.
volatile uint8_t iOverCnt; // Counter to see if user code too long and causes
                           //  interrupt overrun.
volatile uint16_t iBusy;   // Flag is user level interrupt code busy.

volatile uint8_t duty = 0; //duty cycle variable
volatile uint8_t flag = 0; // when switch 1 on ousb board is on, flag is set to 1
uint16_t ct_int = 0;       // counter for jitter pattern array with 200 elements
volatile uint16_t counter; // motor finished 1/2 round, how many 200us interrupte has done  --> we can determine speed of motor
uint16_t counter3 = 0;
uint8_t bit = 0;

int prev = 0, cur = 0; // used to determine rising and falling edge

uint8_t T_sampling = 10;         //10ms
volatile uint8_t pre_speed = 50; // preset the target of motor speed, metric: rounds/second.
volatile uint8_t en_jit = 1;
//volatile uint8_t  step[250];

//variable for digital controller
volatile float x0 = 0, x1 = 0, y = 0, y2 = 0;
volatile float dC[200];
volatile float gain = 0.2272;
int counter4 = 0;

//=============================================================================
//jitter 10% P1

//volatile uint8_t jitter[200] = {53,48,54,46,49,52,53,53,47,55,55,51,47,47,51,48,46,46,49,46,52,46,52,46,47,55,49,53,50,50,51,45,51,48,50,53,55,54,53,51,48,50,52,48,46,48,48,51,52,49,52,50,55,51,46,54,46,55,53,52,53,51,48,50,45,50,50,49,48,49,48,48,55,46,52,50,45,47,47,47,55,53,51,48,54,53,51,51,46,47,50,53,45,51,52,47,50,55,47,54,51,55,51,45,50,47,55,50,45,50,52,48,47,48,53,46,54,45,51,47,50,55,51,49,53,50,46,51,51,52,54,49,48,49,46,49,48,50,54,52,48,51,50,52,47,52,53,50,55,51,51,54,53,46,49,48,54,46,50,53,47,52,55,50,53,48,52,45,50,53,48,54,51,55,52,54,51,49,46,54,50,53,46,51,46,46,52,51,50,48,52,51,54,47,54,50,54,49,52,54};
//==============================================================================
//=============================================================================
//jitter 20% P1

//volatile uint8_t jitter[200] = {55,47,59,43,48,54,56,56,44,60,59,53,43,43,53,47,43,41,47,42,55,43,53,41,44,59,47,57,51,50,51,41,53,46,50,56,59,57,57,52,46,50,54,46,41,46,46,53,53,48,54,51,60,52,42,58,43,59,56,54,55,53,47,49,41,51,49,48,46,48,45,46,59,43,54,49,40,44,45,45,60,57,51,45,58,56,52,52,42,44,51,56,40,53,55,44,49,60,43,57,53,59,52,40,50,44,60,49,40,50,54,46,44,45,56,41,57,40,52,44,49,59,52,48,57,49,43,52,51,53,59,48,47,48,42,47,46,49,58,54,46,52,51,54,44,54,56,49,60,52,52,57,56,42,48,45,58,43,51,56,45,55,59,49,55,47,55,40,51,57,46,57,51,60,54,59,51,48,42,57,49,56,42,51,42,42,53,52,51,45,54,53,58,43,59,51,57,47,54,59};
//==============================================================================
//=============================================================================
//jitter 30% P1

//volatile uint8_t jitter[200] = {58,45,63,39,48,56,58,59,41,65,64,54,40,40,54,45,39,37,46,38,57,39,55,37,41,64,46,60,51,50,52,36,54,44,49,58,64,61,60,54,44,51,55,44,37,45,44,54,55,48,56,51,65,53,37,63,39,64,60,55,58,54,45,49,36,51,49,48,44,47,43,44,64,39,57,49,36,42,42,42,65,60,52,43,62,59,53,54,38,40,51,60,36,54,57,40,49,65,40,61,54,64,53,35,50,40,64,49,35,51,56,44,41,43,59,37,61,36,53,41,49,64,52,47,60,49,39,53,52,55,63,47,45,47,38,46,44,49,62,55,44,53,51,57,42,55,59,49,65,53,53,61,58,38,47,43,62,39,51,59,42,57,64,49,58,45,57,36,51,60,44,61,52,65,56,63,52,47,38,61,49,59,37,52,38,38,55,53,51,43,57,54,62,40,63,51,61,46,57,63};
//==============================================================================
//=============================================================================
//jitter 40% P1

//volatile uint8_t jitter[200] = {60,44,68,36,47,58,61,63,38,69,68,55,36,37,56,43,36,33,44,33,60,36,56,32,38,68,45,64,51,50,52,31,55,42,49,61,69,65,64,55,42,51,57,42,32,43,42,56,57,47,57,52,70,55,33,67,36,68,63,57,61,55,44,48,31,51,48,47,43,46,40,42,68,35,59,48,31,39,40,39,70,63,53,41,66,62,54,55,34,37,52,63,31,55,60,37,49,70,36,65,55,69,54,30,50,37,69,49,30,51,58,42,38,40,62,33,64,31,55,37,49,69,53,46,64,49,35,55,52,57,68,46,44,46,34,45,41,48,66,57,42,54,51,59,39,57,61,48,70,54,53,64,61,33,46,41,66,36,52,61,40,60,69,48,60,43,60,31,51,64,41,64,53,70,58,68,52,46,34,64,48,62,33,53,34,34,56,54,52,41,59,56,66,37,67,52,64,45,59,67};
//==============================================================================

//jitter 10% p2
//volatile uint8_t jitter[200] ={48,46,54,55,47,47,51,50,55,48,53,46,50,49,47,50,54,46,53,47,46,46,46,50,50,46,48,46,52,46,51,55,48,49,53,54,52,51,46,51,51,53,49,50,54,54,54,46,54,46,54,54,46,46,48,47,53,49,45,52,55,48,50,49,48,54,48,48,50,46,48,54,51,53,49,48,48,50,45,49,47,54,53,50,53,54,47,49,45,45,50,54,52,45,48,51,54,55,51,50,47,51,53,51,52,52,50,52,50,49,50,48,50,55,49,50,48,54,50,49,48,50,47,48,49,49,48,52,48,53,53,50,45,51,47,52,46,54,53,50,53,54,47,45,54,45,54,45,54,47,46,50,54,53,46,52,49,47,50,46,51,54,48,55,48,54,55,54,55,50,50,52,46,50,52,53,50,46,47,45,53,48,46,50,45,53,54,48,50,52,54,55,51,48,49,47,54,53,53,52};
//jiter 20% p2
//volatile uint8_t jitter[200] = {46,42,58,60,43,44,52,50,60,46,55,42,49,48,44,51,58,41,57,44,42,41,42,50,50,42,47,42,54,42,51,59,46,48,56,57,54,52,41,53,52,56,48,51,57,57,58,42,58,42,59,57,42,42,46,45,56,49,40,55,59,47,51,47,45,58,45,46,50,42,47,57,51,56,49,46,45,51,40,49,43,57,56,51,55,57,44,48,41,40,50,58,54,40,47,52,57,59,52,49,44,53,55,51,54,55,50,54,50,49,49,46,50,59,49,50,46,58,50,48,45,50,44,47,49,49,45,55,46,57,57,50,41,51,45,53,43,58,55,50,56,57,44,41,58,41,57,40,57,44,43,50,57,57,42,54,48,44,50,42,52,59,46,60,47,58,59,57,59,49,49,54,43,50,53,55,49,43,44,40,56,46,43,51,41,56,58,46,49,54,57,59,51,46,47,44,58,56,55,54};

//jitter 30% p2
//volatile uint8_t jitter[200] ={43,38,62,65,40,41,53,50,65,43,58,38,49,48,41,51,62,37,60,42,39,37,38,49,50,38,45,38,56,38,52,64,44,47,59,61,56,53,37,54,53,58,48,51,61,61,62,38,62,38,63,61,38,38,43,42,59,48,35,57,64,45,51,46,43,62,43,44,50,38,45,61,52,59,48,45,43,51,35,48,40,61,59,51,58,61,41,47,36,35,50,62,55,35,45,54,61,64,52,49,40,54,58,52,56,57,50,57,49,48,49,44,51,64,48,50,44,61,50,47,43,49,42,45,48,48,43,57,45,60,60,51,36,52,42,55,39,63,58,50,60,61,42,36,62,36,61,35,61,40,39,50,61,60,38,57,47,40,49,37,53,63,45,65,45,62,64,61,64,49,49,56,39,49,55,58,49,39,41,35,60,45,39,51,36,60,62,44,49,56,61,64,52,43,46,41,62,59,58,56};

//jiter 40% p2
//volatile uint8_t jitter[200] = {41,34,66,70,37,38,54,49,70,41,60,34,48,47,38,51,67,32,63,39,35,33,34,49,50,34,43,34,59,33,52,69,42,47,62,64,58,54,33,55,54,61,47,51,64,65,66,34,66,34,68,65,34,34,41,39,62,48,30,60,69,44,51,44,41,67,40,42,50,35,44,64,53,62,48,43,40,52,30,48,37,64,63,51,60,64,38,46,32,30,50,66,57,30,43,55,64,68,53,49,37,56,61,53,58,60,51,59,49,48,49,42,51,69,47,50,43,65,50,46,41,49,39,44,47,47,40,59,43,63,64,51,31,53,40,57,35,67,61,50,63,65,39,31,66,32,64,30,64,37,35,50,65,63,34,59,46,37,49,33,54,68,43,70,44,66,69,65,69,49,48,59,36,49,57,61,49,36,38,31,63,43,35,51,32,63,66,42,48,58,65,69,52,41,44,38,65,63,60,58};
//==============================================================================
//p3 10%
//volatile uint8_t jitter[200] = {45,45,55,55,45,45,45,45,45,48,53,46,50,49,47,50,54,46,53,47,46,46,46,50,50,46,48,46,52,46,51,55,48,49,53,54,52,51,46,51,51,53,49,50,54,54,54,46,54,46,54,54,46,46,48,47,53,49,45,52,55,48,50,49,48,54,48,48,50,46,48,54,51,53,49,48,48,50,45,49,47,54,53,50,53,54,47,49,45,45,50,54,52,45,48,51,54,55,51,50,47,51,53,51,52,52,50,52,50,49,50,48,50,55,49,50,48,54,50,49,48,50,47,48,49,49,48,52,48,53,53,50,45,51,47,52,46,54,53,50,53,54,47,45,54,45,54,45,54,47,46,50,54,53,46,52,49,47,50,46,51,54,48,55,48,54,55,54,55,50,50,52,46,50,52,53,50,46,47,45,53,48,46,50,45,53,54,48,50,52,54,55,51,48,49,47,54,53,53,52};
//p3 20%
//volatile uint8_t jitter[200] = {40,40,60,60,40,40,40,40,40,46,55,42,49,48,44,51,58,41,57,44,42,41,42,50,50,42,47,42,54,42,51,59,46,48,56,57,54,52,41,53,52,56,48,51,57,57,58,42,58,42,59,57,42,42,46,45,56,49,40,55,59,47,51,47,45,58,45,46,50,42,47,57,51,56,49,46,45,51,40,49,43,57,56,51,55,57,44,48,41,40,50,58,54,40,47,52,57,59,52,49,44,53,55,51,54,55,50,54,50,49,49,46,50,59,49,50,46,58,50,48,45,50,44,47,49,49,45,55,46,57,57,50,41,51,45,53,43,58,55,50,56,57,44,41,58,41,57,40,57,44,43,50,57,57,42,54,48,44,50,42,52,59,46,60,47,58,59,57,59,49,49,54,43,50,53,55,49,43,44,40,56,46,43,51,41,56,58,46,49,54,57,59,51,46,47,44,58,56,55,54};
//p3 30%
volatile uint8_t jitter[200] = {35, 35, 65, 65, 35, 35, 35, 35, 35, 43, 58, 38, 49, 48, 41, 51, 62, 37, 60, 42, 39, 37, 38, 49, 50, 38, 45, 38, 56, 38, 52, 64, 44, 47, 59, 61, 56, 53, 37, 54, 53, 58, 48, 51, 61, 61, 62, 38, 62, 38, 63, 61, 38, 38, 43, 42, 59, 48, 35, 57, 64, 45, 51, 46, 43, 62, 43, 44, 50, 38, 45, 61, 52, 59, 48, 45, 43, 51, 35, 48, 40, 61, 59, 51, 58, 61, 41, 47, 36, 35, 50, 62, 55, 35, 45, 54, 61, 64, 52, 49, 40, 54, 58, 52, 56, 57, 50, 57, 49, 48, 49, 44, 51, 64, 48, 50, 44, 61, 50, 47, 43, 49, 42, 45, 48, 48, 43, 57, 45, 60, 60, 51, 36, 52, 42, 55, 39, 63, 58, 50, 60, 61, 42, 36, 62, 36, 61, 35, 61, 40, 39, 50, 61, 60, 38, 57, 47, 40, 49, 37, 53, 63, 45, 65, 45, 62, 64, 61, 64, 49, 49, 56, 39, 49, 55, 58, 49, 39, 41, 35, 60, 45, 39, 51, 36, 60, 62, 44, 49, 56, 61, 64, 52, 43, 46, 41, 62, 59, 58, 56};
//p3 40%
//volatile uint8_t jitter[200] = {30,30,70,70,30,30,30,30,30,41,60,34,48,47,38,51,67,32,63,39,35,33,34,49,50,34,43,34,59,33,52,69,42,47,62,64,58,54,33,55,54,61,47,51,64,65,66,34,66,34,68,65,34,34,41,39,62,48,30,60,69,44,51,44,41,67,40,42,50,35,44,64,53,62,48,43,40,52,30,48,37,64,63,51,60,64,38,46,32,30,50,66,57,30,43,55,64,68,53,49,37,56,61,53,58,60,51,59,49,48,49,42,51,69,47,50,43,65,50,46,41,49,39,44,47,47,40,59,43,63,64,51,31,53,40,57,35,67,61,50,63,65,39,31,66,32,64,30,64,37,35,50,65,63,34,59,46,37,49,33,54,68,43,70,44,66,69,65,69,49,48,59,36,49,57,61,49,36,38,31,63,43,35,51,32,63,66,42,48,58,65,69,52,41,44,38,65,63,60,58};

volatile uint8_t j = 0;
//=============== SYSTEM hooks, leave and ignore =============================
/*void control(uint16_t sp) 
{
    x0=  2*3.14*(pre_speed-1000.0/(sp*0.2*2)); //rad/s
    x1= -0.0267*x0 + 0.125*pre_speed*2*3.14;
    //y2 = 0.2272*x1;
    y2 = gain*x1;
    //convert to PWM
    y = y2*255/5;
    if ( y > 255) y = 255 ;
    if ( y < 0) y=0 ; 
    
        duty = (int)y;
    if(counter4<=295)
    {
                dC[counter4] = sp;
                counter4++;
                dC[counter4] = x0;
                counter4++;
                dC[counter4] = x1;
                counter4++;
                dC[counter4] = y;
                counter4++;
                dC[counter4] = y2;
                counter4++;
    }
}
*/
float Kd = 0;
float Ki = 1;
//float Ki = 2.7;
float Kp = 0.046378;
//float Kp = 0.004;
float e = 0, e1 = 0, e2, u = 0, delta_u = 0;
float u1, u2;
volatile float a;
volatile float b;
volatile float c;

void PI_Control(uint16_t sp)
{
        e2 = e1;
        e1 = e;
        e = 2 * 3.14 * (pre_speed - 1000.0 / (sp * 0.2 * 2)); //rad/s
        delta_u = a * e + b * e1 + c * e2;
        //delta_u = e*gain1;
        u = u + delta_u;
        u2 = u;
        if (u > 5.0)
                u = 5.0;
        if (u < 0)
                u = 0;
        u1 = u * 255.0 / 5;

        duty = (int)u1;
        if (counter4 <= 200)
        {
                dC[counter4] = 1000.0 / (sp * 0.4); //speed value rev/second
                counter4++;
                //              dC[counter4] = e;
                //              counter4++;
                //              dC[counter4] = delta_u;
                //              counter4++;
                //              dC[counter4] = u;
                //              counter4++;
                //              dC[counter4] = u1; // PWM value
                //                counter4++;
                //              dC[counter4] = u2;
                //              counter4++;
        }
}
void user_system_200us_interrupt()
{ //--- check for overrun.
        //  PORTB ^= 0x80 ;  // change PB7 every time called.
        if (iBusy)
                ++iOverCnt;
        iBusy = 1;
        //--- put user code here.
        //==============================================================================

        /*
		everytime their is falling/rising each  we record the counter
		
		counter = number of 200us interrupts happen = a  half of round 
		--> based on counter, we can caculate the speed of the motor
		since we have counter --> we can caculate time for motor rotate a half round
		time 1/2 round = counter*200us
		--> time 1 round  = counter*0.2ms*2 (double)
		--> current speed of motor  = 1000/time 1 round  (Hz) or (rounds/second)
		*/
        cur = digitalRead(23);
        if (counter3 < 65000)
                counter3++;
        if (((cur == 0 && prev == 1) || (cur == 1 && prev == 0)))
        {
                counter = counter3;
                //i = i+1;
                counter3 = 0;
                //i++;
        }
        prev = cur;

        if (en_jit == 1 && flag == 1)
        {

                //after 10ms, sampling with jitter
                //==============================================================================

                ct_int++;
                if (ct_int == jitter[j]) //tsampling / 0.2
                {
                        bit = digitalRead(5);
                        bit = bit ^ 1;
                        digitalWrite(5, bit);

                        ct_int = 0;

                        a = Kp + Ki * jitter[j] * 0.2 / 2.0 / 1000;
                        b = -Kp + Ki * jitter[j] * 0.2 / 2.0 / 1000;

                        //control(counter);
                        if (j < 199)
                                j++;
                        else
                                j = 0;
                        PI_Control(counter);
                }
        }

        if (en_jit == 0 && flag == 1)
        {

                //after 10ms, sampling
                //==============================================================================

                ct_int++;
                if (ct_int == T_sampling * 5) // tsampling/0.2ms interrrupt = tsampling*5
                {
                        bit = digitalRead(5);
                        bit = bit ^ 1;
                        digitalWrite(5, bit);

                        ct_int = 0;
                        // caculation in PID controller
                        //control(counter);
                        PI_Control(counter);
                }

                //this part is only used for testing purpose, please commment them when running
                //----BEGIN PART-------------------------------------------------------------------------
                /* if(counter4<=300)
					{	
						dC[counter4] = counter;
						counter4++;
					} */
                //-----END PART-------------------------------------------------------------------------
        }

        //--- finished user code, mark as not busy.
        iBusy = 0;
}

void user_command(uint8_t *get_ctrl, uint16_t *get_addr, uint16_t *val)
{
}

void user_forever_loop()
{ //--- Variables & initializations.duty

        //pb0 is used to enable/disable the motor
        //pinMode(1,OUTPUT); // PB0 set to output
        //digitalWrite(1, LOW) ;  //Set default PB0 low to disable

        // caculation in PID controller
        a = Kp + Ki * T_sampling / 2.0 / 1000 + Kd * 1000.0 / T_sampling;
        b = -Kp + Ki * T_sampling / 2.0 / 1000 - 2 * Kd * 1000.0 / T_sampling;
        c = Kd / T_sampling * 1000.0;

        pwmFreq(4, 2000);     //PB3 or PWM1 set pwmFreq == 2000
        pwmDuty(4, 50);       // set duty cycle = 0 to disable motor
        PORTB = PORTB | 0X80; //for debug purpose
        counter = 65000;
        //pwmDuty(4,0);
        //Check pinC timer
        for (;;)
        {
                digitalWrite(2, digitalRead(23));
                digitalWrite(3, digitalRead(24));
                PORTB = PORTB | 0X40; //for debug purpose
                if (PINC & 0x01)      //switch PC0 is START Button
                {
                        pwmDuty(4, duty); //set
                                          //pwmDuty(4,90);
                        flag = 1;
                }
                else
                {
                        flag = 0;
                        //pwmDuty(4,0);
                }

                BREAKPOINT(3);
        }
}
