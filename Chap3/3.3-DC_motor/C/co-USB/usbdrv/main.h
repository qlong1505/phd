//=============== SYSTEM provided items for user code ===============================
//
//  PURPOSE - these features are supplied by the USB operating system.

extern volatile uint8_t sys_cnt_500us ; // user read only, increments every 500us.
extern volatile uint8_t sys_cnt_100ms ; // user read only, increments every 100ms.
                                        // volatile tells optimizer value may change
                                        // from outside the visible code path.

//------ breakpoint requirements.
extern volatile uint8_t breakpoint ;
extern volatile uint8_t stop ;
#define BREAKPOINT(N) { if (breakpoint & (1<<(N-1))) {stop=N ; while ( stop) ; }}
#define SET_BREAKPOINT(N) { breakpoint |= (1<<(N-1)) ; }
#define CLR_BREAKPOINT(N) { breakpoint &= (~(1<<(N-1))) ; }

#define VERSION 5


