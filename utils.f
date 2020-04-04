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
TIMER_BASE 4 	 +					CONSTANT SYSTIMER_CL0
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
	DUP 0 > IF ELSE NEGATE THEN ;
	
: BIT_FLAG					( value -- flag )
	0 <> ;					\ If value is not 0 it returns TRUE
	
: MILLISECONDS 					( seconds -- milliseconds )
	3E8 * ;				

: MICROSECONDS 					( seconds -- microseconds )
	F4240 * ;			

: CURRENT_TIME 					( -- time )
	SYSTIMER_CL0 @ ;
	
: WAIT 						( microseconds -- )
	CURRENT_TIME
	BEGIN
		DUP CURRENT_TIME		\ Now on the stack: microseconds start_time start_time current_time 	
		- ABS  				\ Now on the stack: microseconds start_time elapsed_time 
	>R OVER R>    <=		
	UNTIL
	DROP DROP ;

: DELAY 					( steps -- )
	BEGIN 					\ We wait until steps = 0
		1 - DUP 
	0 = 
	UNTIL 
	DROP ;
		
: MASK_REGISTER 				( address starting_bit_position bits_num -- masked_register )
	MASK 1 -				\ Sets a bits_num of bits to 1
	SHIFT INVERT				\ Shifts those bits by starting_bit_position and then inverts the bits
	SWAP @ AND ;				\ Performs a logic AND between the current content of the register and the mask	
	
: GPFSEL_ADDRESS 				( pin_number -- GPFSEL_address )
	A / 4 *					\ We put the GPIO pin number on the stack and get
	GPIO_BASE  + ;				\ the address of the appropriate GPFSEL function select register 

: GPFSEL_STARTING_BIT_POSITION			( pin_number -- starting_bit_position )
	A MOD 3 * ;				\ starting_bit_position for the FSEL field in the appropriate GPFSEL register

: SET_PUD					( GPPUDCLK0_MASK, UP/DOWN -- )
	GPPUD !
	150 DELAY
	DUP INVERT SWAP
	GPPUDCLK0 @ OR GPPUDCLK0 !
	150 DELAY
	0 GPPUD !
	GPPUDCLK0 @ AND GPPUDCLK0 ! ;

: SET_GPFSEL					( value pin_number -- )
	DUP GPFSEL_ADDRESS DUP >R SWAP		\ We define a general word that only requires the pin_number and value to set in the appropriate register
	GPFSEL_STARTING_BIT_POSITION		\ We then define more specific words for ease of use
	3 MASK_REGISTER OR R> ! ;

: SET_IN_9					( -- )
	9 0 SET_GPFSEL ;			\ We set GPIO 9 to INPUT
	
: SET_IN_10					( -- )
	10 9 SET_GPFSEL ;			\ We set GPIO 10 to INPUT
	
: SET_ALT0_2					( -- )
	100 2 SET_GPFSEL ;			\ We set GPIO 2 to ALT0
	
: SET_ALT0_3					( -- )
	800 3 SET_GPFSEL			\ We set GPIO 3 to ALT0

: CLEAR_FIFO					( -- )
	BSC1_BASE 4 2 MASK_REGISTER 		\ It clears the FIFO
	20 OR BSC1_BASE ! ;

: SET_I2CEN					( -- )
	BSC1_BASE F 1 MASK_REGISTER 		\ It enables the BSC controller
	8000 OR BSC1_BASE ! ;
	
: START_TRANSFER				( -- )
	BSC1_BASE 7 1 MASK_REGISTER 		\ It starts a new transfer
	80 OR BSC1_BASE ! ;
	
: WRITE_TRANSFER				( -- )
	BSC1_BASE 0 1 MASK_REGISTER		\ 0 = Write Packet
	0 OR BSC1_BASE ! ;

: SET_SLAVE					( -- ) 		
	3F SLAVE ! ;				\ Sets the slave address, 0x3F for our LCD

: SET_DLEN					( bytes_num -- )
	DLEN ! ;				\ It sets the bytes_num to be written 
	
: WRITE_FIFO					( data -- ) 
	FIFO ! ;				\ It puts data into the FIFO
		
: DONE 						( -- )
	STATUS @ 				\ Checks that DONE bit in STATUS register is set
	1 1 LSHIFT 
	AND BIT_FLAG ;
	
: CHECK_STATUS 					( -- )
	BEGIN 					\ Waits until DONE bit in STATUS register is set
		1000 DELAY 
	DONE 
	UNTIL ;
	
: FALLING_EDGE_DETECT_SET_9				( -- )
	GPFEN0 
	9 1 MASK_REGISTER 
	200 OR GPFEN0 ! ;
	
: FALLING_EDGE_DETECT_SET_10				( -- )
	GPFEN0 
	10 1 MASK_REGISTER 
	400 OR GPFEN0 ! ;

: SETUP_9 						( -- )		
	SET_IN_9					\ We set the GPIOs as input and then we set the internal pull DOWN
	GPPUDCLK0 9 1 MASK_REGISTER			\ This is for GPIO 9 
	DOWN SET_PUD ;

: SETUP_10						( -- )
	SET_IN_10					\ We set the GPIOs as input and then we set the internal pull DOWN
	GPPUDCLK0 10 1 MASK_REGISTER			\ This is for GPIO 10
	DOWN SET_PUD ;

: SETUP_BSC						( -- )
	SET_ALT0_2					\ BSC1 is on GPIO pins 2(SDA) and 3(SCL) , so we set them to ALT0
	SET_ALT0_3
	SET_I2CEN ;					\ We enable the BSC controller
	
: FALLING_EDGE_DETECT_SET				( -- )
	FALLING_EDGE_DETECT_SET_9
	FALLING_EDGE_DETECT_SET_10 ;
	
: SETUP
	SETUP_9
	SETUP_10
	SETUP_BSC
	FALLING_EDGE_DETECT_SET 
	0 CURRENT_VALUE !				
	0 SIZE ! ;	
	
	

	

