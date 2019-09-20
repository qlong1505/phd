/* Name: main.c
 * Project: open-usb-io, based on SRUSB-Mega32
 * License: GNU GPL v2  
 */



#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h>
#include <avr/boot.h>

#include "../usbdrv/main.h"
#include "../usbdrv/usbdrv.h"
#include "../usbdrv/oddebug.h"
#include <util/delay.h>

//------ user code routines that must exist in the user code (user_code.c).
void user_forever_loop() ;           // Background forever loop, can be all users code.
void user_system_200us_interrupt() ; // Call to user code every 500us.
void user_command( uint8_t* get_ctrl, uint16_t* get_addr, uint16_t* val) ;
                                     // ousb command "user" calls user code.

extern uchar       usbPollActive ;   // =1 if usbPoll active, stops interrupt overrun.
                                     // defined in usbdrv.c



//This is the 'HID Report Descriptor', remember when changing this that usbconfig.h needs to be updated as well to reflect the new length.

PROGMEM char usbHidReportDescriptor[78] = {
    0x06, 0x00, 0xff,              // USAGE_PAGE (Generic Desktop)
    0x09, 0x01,                    // USAGE (Vendor Usage 1)
    0xa1, 0x01,                    // COLLECTION (Application)
    0x15, 0x00,                    //   LOGICAL_MINIMUM (0)			** 
    0x26, 0xff, 0x00,              //   LOGICAL_MAXIMUM (255)		here we say that the device can report back 6 pieces of information (report_size) of 8 bits each (0-255)
    0x75, 0x08,                    //   REPORT_SIZE (8) 				

//Read/Write IO/EEPROM (status byte + 16 bit addr, + 16 bit data)
    0x85, 0x02,                    //   REPORT_ID (1)			*the reason for the Id's is that there is 2 kinds of reports the client can request (this is the command to get info on sizes), also used to leave bootloader (if given as a set request)
    0x95, 0x05,                    //   REPORT_COUNT (4)				
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf)		*data (not constant), variable (not array), absolute (not relative), buffered bytes (not a bit field)**      
// All port read and version number ID.
    0x85, 0x03,                    //   REPORT_ID (1)
    0x95, 0x05,                    //   REPORT_COUNT (4)				
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf) *data (not constant), variable (not array), absolute (not relative), buffered bytes (not a bit field)**
//  User command.
    0x85, 0x04,                    //   REPORT_ID (1)
    0x95, 0x05,                    //   REPORT_COUNT (4)				
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf) *data (not constant), variable (not array), absolute (not relative), buffered bytes (not a bit field)**
//  Read RAM block
    0x85, 0x05,                    //   REPORT_ID (1)
    0x95, 0x05,                    //   REPORT_COUNT (4)				
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf) *data (not constant), variable (not array), absolute (not relative), buffered bytes (not a bit field)**
//  Write RAM block.
    0x85, 0x06,                    //   REPORT_ID (1)
    0x95, 0x05,                    //   REPORT_COUNT (4)				
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf) *data (not constant), variable (not array), absolute (not relative), buffered bytes (not a bit field)**

//Leave Bootloader / Read Bootloader.
    0x85, 0x29,                    //   REPORT_ID 
    0x95, 0x06,                    //   REPORT_COUNT 			
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf)		
//Upload
    0x85, 0x2A,                    //   REPORT_ID 
    0x95, 0x83,                    //   REPORT_COUNT 			
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf)		

    0xc0                           // END_COLLECTION
};

//---------- USB variables.
uint8_t replyBuf[8];	//Buffer used for reply
uint8_t reportId = -1;	//Variable holding the last report we recieved, this is needed for dealing with >7 byte reports in usbfunctionwrite

uint8_t get_ctrl;		//Status byte used for setting up reads and writes.
                                // bit0 0=read 1=write, bit1 0=RAM 1=EE, bit2 0=byte 1=word.
uint16_t get_addr;		//address to be read on next read report
uint16_t val ;                  // also val saved from write.

//For Bootloader
unsigned long currentAddress;
uint8_t offset;
uint8_t exitMainloop;

//---------- variables for user access.
volatile uint8_t sys_cnt_500us ; // user read only, increments every 500us.
volatile uint8_t sys_cnt_100ms ; // user read only, increments every 100ms.
volatile uint8_t breakpoint=0 ;
volatile uint8_t stop=0 ;


USB_PUBLIC uchar usbFunctionSetup(uchar data[8]) //=====================================
{
usbRequest_t    *rq = (void *)data;

    if(rq->bRequest == USBRQ_HID_SET_REPORT){ 
		reportId = rq->wValue.bytes[0];
		offset = 0;
        return 0xff; //Call usb functionwrite.
    }else if(rq->bRequest == USBRQ_HID_GET_REPORT){ //the only report we ever recieve this for is 1, so it's not checked.
      if(1){
		replyBuf[0] = rq->wValue.bytes[0];
		usbMsgPtr = replyBuf;
		if(rq->wValue.bytes[0] == 2) {	//read io/eeprom 
			replyBuf[1] = get_ctrl;
			replyBuf[2] = get_addr >> 8;
			replyBuf[3] = get_addr & 0xff;
			if(get_ctrl&2){ // EEPROM read
				//for ( offset=1 ; offset++ ; offset <=2)
                                get_ctrl = 1 ;
                                while ( get_ctrl < 6) 
				 { while(EECR & (1 << EEWE)); // wait for ready.
				   EEAR = get_addr++;
				   EECR |= 1 << EERE;
				   replyBuf[get_ctrl++] = EEDR ;
                                 }
			}
			else{ // io/RAM read
				if(get_addr == 0x46 || get_addr == 0x48 || get_addr == 0x4A || get_addr == 0x4C || get_addr == 0x3E || get_addr == 0x24){
					val = _MMIO_WORD(get_addr);
					replyBuf[4] = val >> 8;
					replyBuf[5] = val & 0xff;
				}
				else {
					replyBuf[4] = 0;
					replyBuf[5] = _MMIO_BYTE(get_addr);
				}
			}
			return 6;
		}
		else if(rq->wValue.bytes[0] == 3) { //get the digital inputs
			replyBuf[1] = PINA;
			replyBuf[2] = PINB;
			replyBuf[3] = PINC;
			replyBuf[4] = PIND;
			replyBuf[5] = VERSION ;
			return 6;
		}
		else if(rq->wValue.bytes[0] == 4) { //user call
                        user_command( &get_ctrl, &get_addr, &val) ;
			replyBuf[1] = get_ctrl;
			replyBuf[2] = get_addr >> 8 ;
			replyBuf[3] = get_addr & 0xFF;
			replyBuf[4] = val >> 8 ;
			replyBuf[5] = val & 0xFF ;
                        return 6;
		}
		else if(rq->wValue.bytes[0] == 5) { //read ram block
                        uint8_t* p_addr ;
                        p_addr = (uint8_t*) get_addr ;
                        replyBuf[1] = *p_addr++ ;
                        replyBuf[2] = *p_addr++ ;
                        replyBuf[3] = *p_addr++ ;
                        replyBuf[4] = *p_addr++ ;
                        replyBuf[5] = *p_addr ;
                        return 6;
		}
		else if(rq->wValue.bytes[0] == 0x29){
			replyBuf[1] = SPM_PAGESIZE & 0xff;
			replyBuf[2] = SPM_PAGESIZE >> 8;
			replyBuf[3] = (uint8_t) ( (((long)(FLASHEND) + 1)      ) & 0xff);
			replyBuf[4] = (uint8_t) ( (((long)(FLASHEND) + 1) >>  8) & 0xff);
			replyBuf[5] = (uint8_t) ( (((long)(FLASHEND) + 1) >> 16) & 0xff);
			replyBuf[6] = (uint8_t) ( (((long)(FLASHEND) + 1) >> 24) & 0xff);
			return 7;

		}
      }
    }
    return 0;

}


uchar usbFunctionWrite(uchar *data, uchar len) //===========================================
{
union {
    unsigned long   l;
    unsigned short  s[2];
    uchar           c[4];
}       address;
	if(reportId == 2){ //---write/set up read of io/eeprom
		get_ctrl = data[1];
		get_addr = (data[2] << 8) | data[3];
		val      = (data[4] << 8) | data[5];
		if(data[1] & 1){ //perform a write
			if(data[1] & 2) {	//eeprom
				//--- byte 1
				while(EECR & (1 << EEWE));
				EEAR = get_addr;
				EEDR = data[5];
				cli(); // must follow in a couple of cycles, block intr
				EECR |= 1 << EEMWE;
				EECR |= 1 << EEWE;
				sei();
				//--- byte 2
				if ( get_ctrl & 4){
				  while(EECR & (1 << EEWE));
				  EEAR = get_addr;
				  EEDR = data[4];
				  cli(); // must follow in a couple of cycles, block intr
				  EECR |= 1 << EEMWE;
				  EECR |= 1 << EEWE;
				  sei();
                                }
			}
			else{ //---io space, byte or word writes, USB pins left alone.
				if(get_addr == 0x31 || get_addr == 0x32) 
					_MMIO_BYTE(get_addr) = ( _MMIO_BYTE(get_addr) & USBMASK ) | ( data[5] & ~USBMASK);
				else if(get_addr == 0x46 || get_addr == 0x48 || get_addr == 0x4A || get_addr == 0x4C || get_addr == 0x3E || get_addr == 0x24)
					_MMIO_WORD(get_addr) = val;
				else 
					_MMIO_BYTE(get_addr) = data[5];
			}
		}
	
	}
    else if(reportId == 0x29){     /* leave boot loader */
        exitMainloop = 1;
        return 1;
    }else if(reportId == 0x2A){    /* write page */
        if(offset == 0){
            data++;
            address.c[0] = *data++;
            address.c[1] = *data++;
            address.c[2] = *data++;
            address.c[3] = 0;
            len -= 4;
        }else{
            address.l = currentAddress;
        }
        offset += len;
        len >>= 1;
        do{
            if((address.s[0] & (SPM_PAGESIZE - 1)) == 0){   /* if page start: erase */
                cli();
                boot_page_erase(address.l);     /* erase page */
                sei();
                boot_spm_busy_wait();           /* wait until page is erased */
            }
            cli();
            boot_page_fill(address.l, *(short *)data);
            sei();
            address.l += 2;
            data += 2;
            /* write page when we cross page boundary */
            if((address.s[0] & (SPM_PAGESIZE - 1)) == 0){
                cli();
                boot_page_write(address.l - 2);
                sei();
                boot_spm_busy_wait();
            }
        }while(--len != 0);
        currentAddress = address.l;
        if(offset < 128){
            return 0;
        }else{
            reportId = -1;
            return 1;
        }
    }else if( (reportId >= 0x04) ||  //------ 4 user write command, 5 read RAM block
              (reportId <= 0x06)){   //------ 6 write byte/word
		get_ctrl = data[1];
		get_addr = (data[2] << 8) | data[3];
		val      = (data[4] << 8) | data[5];
                if (reportId == 6)
                { if (get_ctrl == 1)
                        _MMIO_BYTE(get_addr) = data[5] ;
                  else  _MMIO_WORD(get_addr) = data[5] | data[4] << 8 ;
                }
    }
    return 1;
}


//==================== Timer 2 Interrupt ============================================
//
// PURPOSE - drive usbPoll() every 500us, so can leave background level all for
//           user code.

//static uint8_t cnt_100ms = 0 ;


//--- 200us version.
ISR(TIMER2_COMP_vect, ISR_NOBLOCK)
{//--- 12 MHz/32 counts, 75 get 200us.
   OCR2 = 75 ; 
   
 //--- no system timers sys_cnt_500us or sys_cnt_100ms to save time..
    
 //--- call user code every 500us, must be short!
   user_system_200us_interrupt() ;

 //--- kick the dog, check for usbPoll activities
   wdt_reset();
   if ( usbPollActive) 
     return ;   // overrun so don't call again till previous version finished.
   usbPoll();   // previous call finished so call again.

}


//--- 500us interrupt.
/*
ISR(TIMER2_COMP_vect, ISR_NOBLOCK)
{//--- use dither to correct for count being 187.5, get 500us exactly, on average.
   if (OCR2 == 187)
        OCR2 = 188 ;
   else OCR2 = 187 ; 
   
 //--- increment software timers for user code.
   ++sys_cnt_500us ;
   ++cnt_100ms ;
   if (cnt_100ms >= 200)
    { cnt_100ms = 0 ;
      ++sys_cnt_100ms ;
    }
    
  //--- call user code every 500us, must be short!
    user_system_500us_interrupt() ;

  //--- kick the dog, check for usbPoll activities
    wdt_reset();
    if ( usbPollActive) 
      return ;   // overrun so don't call again till previous version finished.
    usbPoll();   // previous call finished so call again.
}
*/



int main(void) //=============================================================================
{
    
//------ Initializations for usb.	
    wdt_enable(WDTO_1S);
    //odDebugInit();
    
//--- We fake an USB disconnect by pulling D+ and D- to 0 during reset. This is
// necessary if we had a watchdog reset or brownout reset to notify the host
// that it should re-enumerate the device. Otherwise the host's and device's
// concept of the device-ID would be out of sync.
 
    DDRD  = 0xBE ;   // only inputs RX=PD0, ICP1=PD6 
    PORTD = 0;          // output zero, no pullups on inputs.
    //DDRD = ~0;          // output SE0 for faked USB disconnect.
    uchar   i = 0;
    while(--i){         // fake USB disconnect for > 500 ms.
        wdt_reset();
        _delay_ms(2);
    }
    DDRD = DDRD & ~(USBMASK) ;    // all outputs except USB data, RXD/PD0, PD6
    usbInit();
    sei();

//--- Timer 2 is used as a 500 us interrupt to drive usbPoll, setup timer 2 here.
    TCCR2 = 0x0B ;        // Timer 2 as counter timer, count up to limit.
    OCR2  = 187   ;       // given 12 Mhz clock and /32 about 500 us interrupt.
    ASSR  = 0 ;           // ensure no external clock.
    TIMSK |= 0x80 ;       // enable OCIE2 interrupt.
	

//--- set ports to suit default pin use.
    ADCSRA = _BV(ADEN) | _BV(ADSC) |  _BV(ADPS2) | _BV(ADPS1) | _BV(ADPS0);
    ADMUX  = _BV(REFS0);
    
    PORTA= 0x00 ; // turn off PORTA pullups.
    DDRA = 0x00 ; // all port A inputs.
    PORTB= 0x00 ; // all PORTB outputs low.
    DDRB = 0xFF ; // all port B outputs.
    PORTC= 0xFF ; // all PORTC pull-ups on.
    DDRC = 0x00 ; // all port C inputs.
    //DDRD set to outputs above.
    
    UBRRL =  187 ;                             // UART 12 MHz xtal, 9600 baud.
    UCSRB = (UCSRB | _BV(RXEN) | _BV(TXEN) );  // Enable UART receiver and transmitter.

	
//--- forever loop.
    user_forever_loop() ;
    return 0;
}
