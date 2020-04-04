\ The following words are written for the I2C protocol and the display (QAPASS LCD 1602) and expander(PCF8574AT) specifications


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
	DUP 4MSB				\ We operate in 4 bit mode so we have to send the 4MSB and 4LSB twice
	DUP C +	SEND				\ D7-D6-D5-D4=MSB BL=1 EN=1 RW=0 RS=0 ( 0xC )
	8 + SEND				\ D7-D6-D5-D4=MSB BL=1 EN=0 RW=0 RS=0 ( 0x8 )
	DUP 4LSB
	DUP C + SEND
	8 + SEND
	DROP ;
	
: SEND_CHAR					( ASCII_code -- )
	DUP 4MSB				\ We send the ASCII_code for the character
	DUP D + SEND				\ D7-D6-D5-D4=MSB BL=1 EN=1 RW=0 RS=1 ( 0xD )
	9 + SEND				\ D7-D6-D5-D4=MSB BL=1 EN=0 RW=0 RS=1 ( 0x9 )
	DUP 4LSB
	DUP D + SEND
	9 + SEND 
	DROP ;

\ The display functions are specified in the QAPASS 1602 LCD datasheet
\ Note: when we first turn the display on it is in 8 bit mode
	
: FUNCTION_SET					( -- )
	2C SEND					\ D7-D6-D5-D4=0010 (MSB) BL=1 EN=1 RW=0 RS=0 Initialize Lcd in 4-bit mode
	A8 SEND ;				\ D7-D6-D5-D4=1010 (LSB) BL=1 EN=0 RW=0 RS=0
	
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
	
	
