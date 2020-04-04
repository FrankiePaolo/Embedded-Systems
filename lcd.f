\ The following words are written for the I2C protocol and the expander specifications


: SEND						( data -- ) 
	CLEAR_FIFO				\ It clears the FIFO
	1 SET_DLEN 				\ We will write 1 byte into the FIFO
	WRITE_FIFO 				\ We put data in the FIFO
	SET_SLAVE				\ We set the slave address
	WRITE_TRANSFER				\ We want to write
	START_TRANSFER  			\ It starts the transfer
	CHECK_STATUS ; 				\ It checks that the transfer is done
	
: 4LSB						( -- )
	F AND 4 LSHIFT ;			\ These are the 4 least significant bits
	
: 4MSB						( -- )
	F0 AND ;				\ These are the 4 most significant bits
	
: SEND_CMD					( cmd -- )
	DUP 4MSB				\ UPDATE with comments
	DUP C +	SEND				 
	8 + SEND
	DUP 4LSB
	DUP C + SEND
	8 + SEND
	DROP ;
	
: SEND_CHAR					( char -- )
	DUP 4MSB				\ UPDATE with comments
	DUP D + SEND
	9 + SEND
	DUP 4LSB
	DUP D + SEND
	9 + SEND 
	DROP ;


\ The following words are the display functions

	
: FUNCTION_SET					( -- )
	2C SEND					\ D7-D6-D5-D4=0010 (MSB) BL=1 EN=1 RW=0 RS=0 Initialize Lcd in 4-bit mode
	28 SEND ;				\ D7-D6-D5-D4=0010 (LSB) BL=1 EN=0 RW=0 RS=0
	
: CLEAR_DISPLAY					( -- )
	01 SEND_CMD ;				\ It clears the display

: DISPLAY_ON					( -- )
	0F SEND_CMD ;				\ It turns the display ON
	
: DISPLAY_LSHIFT				( -- )
	13 SEND_CMD ;				\ It shifts the display to the left
	
: DISPLAY_RSHIFT				( -- )
	17 SEND_CMD ;				\ It shifts the display to the right
	
: LCD_INIT					( -- )
	FUNCTION_SET				\ It initializes the display
	100 DELAY
	DISPLAY_ON ;
	
	
