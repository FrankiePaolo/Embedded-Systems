HEX
3F000000				 		CONSTANT PERI_BASE
1	 						CONSTANT OUTPUT
0							CONSTANT INPUT
1							CONSTANT DOWN
2							CONSTANT UP
PERI_BASE 200000 + 					CONSTANT GPIO_BASE
GPIO_BASE 1C 	 +      				CONSTANT GPSET0
GPIO_BASE 28 	 +     					CONSTANT GPCLR0
GPIO_BASE 34 	 +					CONSTANT GPLEV0
GPIO_BASE 40 	 +					CONSTANT GPEDS0
GPIO_BASE 58 	 +					CONSTANT GPFEN0
GPIO_BASE 94 	 +					CONSTANT GPPUD				
GPIO_BASE 98 	 +					CONSTANT GPPUDCLK0			
PERI_BASE 3000   +	 				CONSTANT TIMER_BASE
TIMER_BASE 4 	 +					CONSTANT SYSTIMER_CLO
PERI_BASE 804000 + 					CONSTANT BSC1_BASE
BSC1_BASE 4 + 						CONSTANT STATUS    		
BSC1_BASE 8 +						CONSTANT DLEN 			\ Data length
BSC1_BASE C +						CONSTANT SLAVE			\ Slave Address	
BSC1_BASE 10 +						CONSTANT FIFO			\ Data FIFO	



: SHIFT	 					( offset value -- shifted_value )
	SWAP LSHIFT ;	
: MASK  					( offset -- shifted_value )
	1 SHIFT ;
: ABS 						( n -- |n| )
	DUP 0 > IF ELSE NEGATE THEN ;		\ It returns the absolute value of n
	
: BIT_FLAG					( value -- flag )
	0 <> ;					\ If value is not 0 it returns TRUE

: CHECK						( v1 v2 -- flag )
	SWAP DUP ROT AND BIT_FLAG ;		\ Performs the AND between 2 values and returns a flag 
	
: MILLISECONDS 					( seconds -- milliseconds )
	3E8 * ;				

: MICROSECONDS 					( seconds -- microseconds )
	F4240 * ;			

: CURRENT_TIME 					( -- time )
	SYSTIMER_CLO @ ;			\ We only use the lower 32 bits of the system timer
	
: WAIT 						( microseconds -- )
	CURRENT_TIME				\ We define a word that requires the time to wait in microseconds on the stack
	BEGIN
		DUP CURRENT_TIME		\ Now on the stack: microseconds start_time start_time current_time 	
		- ABS  				\ Now on the stack: microseconds start_time elapsed_time 
	>R OVER R>    <=		
	UNTIL
	DROP DROP ;

: DELAY 					( steps -- )
	BEGIN 					\ Busy loops until steps = 0
		1 - DUP 
	0 = 
	UNTIL 
	DROP ;					\ Keeps the stack empty
 	
: WITHIN					( a b c -- p )		\ Where p = ((a >= b) && (a < c))
	-ROT					( b c a )
	OVER					( b c a c )
	<= IF
		> IF				( b c -- )
			TRUE
		ELSE
			FALSE
		THEN
	ELSE
		2DROP				( b c -- )
		FALSE
	THEN ;

: MASK_REGISTER 				( address starting_bit_position bits_num -- masked_register )
	MASK 1 -				\ Sets a bits_num of bits to 1
	SHIFT INVERT				\ Shifts those bits by starting_bit_position and then inverts the bits
	SWAP @ AND ;				\ Performs a logic AND between the current content of the register and the mask	
	
: GPFSEL_ADDRESS 				( pin_number -- GPFSEL_address )
	A / 4 *					\ We put the GPIO pin number on the stack and get
	GPIO_BASE  + ;				\ the address of the appropriate GPFSEL function select register 

: GPFSEL_STARTING_BIT_POSITION			( pin_number -- starting_bit_position )
	A MOD 3 * ;				\ starting_bit_position for the appropriate FSEL field in the appropriate GPFSEL register

: SET_PUD					( GPPUDCLK0_MASK UP/DOWN -- )
	GPPUD !
	150 DELAY
	DUP INVERT SWAP
	GPPUDCLK0 @ OR GPPUDCLK0 !
	150 DELAY
	0 GPPUD !
	GPPUDCLK0 @ AND GPPUDCLK0 ! ;

: SET_PULL					( UP/DOWN pin_number -- )
	GPPUDCLK0 SWAP 1 MASK_REGISTER		\ We define a general word that works with any pin_number  
	SWAP SET_PUD ;

: SET_GPFSEL					( value pin_number -- )
	DUP GPFSEL_ADDRESS DUP >R SWAP		\ We define a general word that only requires the pin_number and value to set the appropriate GPFSEL register
	GPFSEL_STARTING_BIT_POSITION		\ We then define more specific words for ease of use
	3 MASK_REGISTER OR R> ! ;

: SET_REGISTER					( value starting_bit_position bits_num address -- )
	DUP >R ROT ROT MASK_REGISTER 		\ We define a general word for any field of any register
	OR R> ! ;				\ We then define more specific words for ease of use

: SET_BSC1					( value starting_bit_position bits_num -- )
	BSC1_BASE SET_REGISTER ; 		\ We define a general word for any field of the BSC1_BASE register
	
: SET_GPFEN0					( value starting_bit_position bits_num -- )
	GPFEN0 SET_REGISTER ; 			\ We define a general word for any field of the GPFEN0 register

: SET_IN_9					( -- )
	INPUT 9 SET_GPFSEL ;			\ Sets GPIO 9 to INPUT
	
: SET_IN_10					( -- )
	INPUT 10 SET_GPFSEL ;			\ Sets GPIO 10 to INPUT
	
: SET_ALT0_2					( -- )
	100 2 SET_GPFSEL ;			\ Sets GPIO 2 to ALT0
	
: SET_ALT0_3					( -- )
	800 3 SET_GPFSEL ;			\ Sets GPIO 3 to ALT0

: CLEAR_FIFO					( -- )
	20 4 2 SET_BSC1 ;			\ Clears the FIFO

: SET_I2CEN					( -- )
	8000 F 1 SET_BSC1 ;			\ Enables the BSC controller
		
: START_TRANSFER				( -- )
	80 7 1 SET_BSC1	;			\ Starts a new transfer
	
: WRITE_TRANSFER				( -- )
	0 0 1 SET_BSC1 ;			\ 0 = Writes Packet

: SET_SLAVE					( -- ) 		
	3F SLAVE ! ;				\ Sets the slave address, 0x3F for our LCD

: SET_DLEN					( bytes_num -- )
	DLEN ! ;				\ Sets the bytes_num to be written 
	
: WRITE_FIFO					( data -- ) 
	FIFO ! ;				\ Puts data into the FIFO
		
: DONE 						( -- flag )
	STATUS @ 				\ Checks that DONE bit in STATUS register is set and returns flag
	2 AND 
	BIT_FLAG ;
	
: CHECK_STATUS 					( -- )
	BEGIN 					\ Waits until DONE bit in STATUS register is set
		1000 DELAY 
	DONE 
	UNTIL ;
	
: FALLING_EDGE_SET_9				( -- )
	200 9 1 SET_GPFEN0 ;			\ A falling edge transition in GPIO 9 sets a bit in the event detect status registers
	
: FALLING_EDGE_SET_10				( -- )
	400 10 1 SET_GPFEN0 ;			\ A falling edge transition in GPIO 10 sets a bit in the event detect status registers
	
: SETUP_GPIO_9 					( -- )		
	SET_IN_9				\ Sets GPIO 9 as input 
	DOWN 9 SET_PULL ; 			\ Sets the internal pull DOWN

: SETUP_GPIO_10					( -- )
	SET_IN_10				\ Sets GPIO 10 as input 
	DOWN 10 SET_PULL ;			\ Sets the internal pull DOWN
	 
: SETUP_BSC					( -- )
	SET_ALT0_2				\ BSC1 is on GPIO pins 2(SDA) and 3(SCL) , therefore we set them to ALT0
	SET_ALT0_3				\ SDA for data and SCL for the clock
	SET_I2CEN ;				\ Enables the BSC controller
	
: FALLING_EDGE_SET				( -- )
	FALLING_EDGE_SET_9			\ A falling edge transition in GPIO 9 and GPIO 10 sets a bit in the event detect status registers 
	FALLING_EDGE_SET_10 ;
	
	

