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

: 150_DELAY
	0
	BEGIN
	   	1 + DUP
	   	150 >=
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
	150_DELAY
	DUP INVERT SWAP
	GPPUDCLK0 @ OR GPPUDCLK0 !
	150_DELAY
	0 GPPUD !
	GPPUDCLK0 @ AND GPPUDCLK0 ! ;


\ The following words are used only for debugging
\ To be updated with higher levels of abstraction

: SET_IN_9 					( -- )
	9 GPFSEL_ADDRESS 			\ We set GPIO 9 to INPUT
	9 GPFSEL_STARTING_BIT_POSITION 
	3 MASK_REGISTER GPIO_BASE ! ;		
	
: SET_IN_10					( -- )
	10 GPFSEL_ADDRESS 			\ We set GPIO 10 to INPUT
	10 GPFSEL_STARTING_BIT_POSITION 
	3 MASK_REGISTER GPIO_BASE ! ;		

: SET_ALT0_2					( -- )
	GPIO_BASE 				\ We set GPIO 2 to ALT0
	2 GPFSEL_STARTING_BIT_POSITION 
	3 MASK_REGISTER 				
	100 OR GPIO_BASE ! ;
	
: SET_ALT0_3					( -- )
	GPIO_BASE 				\ We set GPIO 3 to ALT0
	3 GPFSEL_STARTING_BIT_POSITION 		
	3 MASK_REGISTER 				
	800 OR GPIO_BASE ! ;				

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
	27 SLAVE ! ;				\ We set the slave address, 0x27 for our LCD

: SET_DLEN					( bytes_num -- )
	DLEN ! ;				\ It sets the bytes_num to be written 
	
: WRITE_FIFO					( data -- ) 
	FIFO ! ;				\ It puts data into the FIFO

: DONE 						( -- flag )
	STATUS 1 1 MASK_REGISTER 		\ If the transfer is compleate we get TRUE
	2 AND BIT_FLAG ;

: CHECK_STATUS 					( -- )
	BEGIN					\ It checks that the transfer is done
		150_DELAY	
		DONE
	UNTIL ;
	

