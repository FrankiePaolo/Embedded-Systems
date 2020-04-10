VARIABLE 							 LINE_COUNTER	\ This variable keeps track of the cursor position on the display, 1 to 16(decimal) for the first display line, 17 to 32 (decimal) for the second display line

\ The following words are written for the I2C protocol and the display (QAPASS LCD 1602) and expander(PCF8574AT) specifications

: LINE_COUNTER++				( LINE_COUNTER_value -- )
	LINE_COUNTER @ 1 + LINE_COUNTER ! ;	\ It increases the LINE_COUNTER value
	
: LINE_COUNTER--				( LINE_COUNTER_value -- )
	LINE_COUNTER @ 1 - LINE_COUNTER ! ;	\ It decreases the LINE_COUNTER value

: SEND						( data -- ) 
	CLEAR_FIFO				\ It clears the FIFO
	1 SET_DLEN 				\ We will write 1 byte into the FIFO
	WRITE_FIFO 				\ We put data in the FIFO
	SET_SLAVE				\ We set the slave address
	WRITE_TRANSFER				\ We want to write
	START_TRANSFER  			\ It starts the transfer
	CHECK_STATUS ; 				\ It checks that the transfer is done
	
: 4LSB						( cmd -- 4lsb )
	F AND 4 LSHIFT ;			\ These are the 4 least significant bits
	
: 4MSB						( cmd -- 4msb )
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
	2C SEND					\ D7-D6-D5-D4=0010 (MSB) BL=1 EN=1 RW=0 RS=0 Initialize Lcd in 4-bit mode 2C SEND
	88 SEND ;				\ D3-D2-D1-D0=1010 (LSB) BL=1 EN=0 RW=0 RS=0

: CLEAR_DISPLAY					( -- )
	01 SEND_CMD 				\ It clears the display and sets the cursor to top left corner
	1 LINE_COUNTER ! ;			\ Sets LINE_COUNTER to first position (1)

: DISPLAY_ON					( -- )
	0F SEND_CMD ;				\ It turns the display ON
	
: LSHIFT_CMD					( -- )
	13 SEND_CMD 				\ It shifts the display to the left
	LINE_COUNTER-- ;			\ Decreases the LINE_COUNTER value
	
: RSHIFT_CMD					( -- )
	17 SEND_CMD 				\ It shifts the display to the right
	LINE_COUNTER++ ;			\ Increases the LINE_COUNTER value
	
: FIRST_LINE					( -- )
	80 SEND_CMD 				\ Sets the cursor position counter to the first position of the first line without easing RAM data
	1 LINE_COUNTER ! ;			\ Sets LINE_COUNTER to first position (1)
	
: LAST_FIRST_LINE				( -- )
	8F SEND_CMD				\ Sets the cursor position counter to last position of the first line without easing RAM data
	10 LINE_COUNTER ! ;			\ Sets LINE_COUNTER to position 16(dec)
		
: SECOND_LINE					( -- )
	C0 SEND_CMD 				\ Sets the cursor position counter to the first position of the second line without easing RAM data
	11 LINE_COUNTER ! ;			\ Sets LINE_COUNTER to position 17(dec)

: LAST_SECOND_LINE				( -- )
	CF SEND_CMD				\ Sets the cursor position counter to last position of the second line without easing RAM data
	20 LINE_COUNTER ! ;			\ Sets LINE_COUNTER to position 32(dec)
	
: LCD_INIT					( -- )
	FUNCTION_SET				\ It initializes the display
	100 DELAY
	DISPLAY_ON 
	1 LINE_COUNTER ! ;			\ Sets LINE_COUNTER to first position (1)
	
: DISPLAY_LSHIFT				( -- )
	LINE_COUNTER @
	DUP 1 = 
	IF
		LAST_SECOND_LINE		\ Sets the cursor position and LINE_COUNTER to last position of the second line
	ELSE
	DUP 11 =
	IF
		LAST_FIRST_LINE			\ Sets the cursor position and LINE_COUNTER to last position of the first line
	ELSE
		LSHIFT_CMD			\ Shifts the display to the left and decreases the LINE_COUNTER value
	THEN
	THEN
	DROP ;

: DISPLAY_RSHIFT				( -- )
	LINE_COUNTER @
	DUP 10 =
	IF
		SECOND_LINE			\ Sets the cursor position and LINE_COUNTER to first position of the second line
	ELSE
	DUP 20 =
	IF
		FIRST_LINE			\ Sets the cursor position and LINE_COUNTER to first position of the first line
	ELSE
		RSHIFT_CMD			\ It shifts the display to the right
	THEN
	THEN
	DROP ;

: DISPLAY_CHAR					( ASCII_code -- )
	SEND_CHAR
	LINE_COUNTER @
	DUP 10 =
	IF
		SECOND_LINE			\ Sets the cursor position and LINE_COUNTER to first position of the second line
	ELSE
	DUP 20 =
	IF
		FIRST_LINE			\ Sets the cursor position and LINE_COUNTER to first position of the first line
	ELSE
		LINE_COUNTER++
	THEN
	THEN 
	DROP ;

	
	
