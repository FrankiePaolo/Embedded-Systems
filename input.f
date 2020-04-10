VARIABLE 							 CURRENT_VALUE
VARIABLE 							 SIZE 
8 							CONSTANT SIZE_REQUESTED 			\ Size of display command ( in our instance it's a byte )		



: SETUP						( -- )		
	SETUP_GPIO_9				
	SETUP_GPIO_10
	SETUP_BSC
	FALLING_EDGE_DETECT_SET 
	0 CURRENT_VALUE !				
	0 SIZE ! ;	
	
: STATUS_MASK					( -- masked_register )
	GPEDS0 10 1 MASK_REGISTER 		\ Provides a mask of GPEDS0 for GPIO 9 and 10
	GPEDS0 9 1 MASK_REGISTER 
	OR ;	
	
: CLEAR_STATUS					( -- )
	STATUS_MASK 				\ Clears the STATUS register for the appropriate GPIO pins
	600 OR 
	GPEDS0 ! ; 					
	
: IS_PRESSED					( -- )
	BEGIN					\ Waits until the button has been released	
		STATUS_MASK 
		GPEDS0 @ AND 
		DUP 0 <>
		IF
			1 MILLISECONDS DELAY	\ Makes sure the button has properly been released, avoiding double reads
			GPLEV0 @ INVERT AND 	
		THEN 
	UNTIL ;

: BUTTONS					( -- 0/1 )	
	IS_PRESSED				\ Waits for the button to be released
	GPEDS0 @ 				
	DUP 400 AND BIT_FLAG		
	IF					
		DROP				\ We make sure not to leave the GPEDS0 content on the stack
		0 				\ Leaves on the stack either 0 or 1
	ELSE
	DUP 200 AND BIT_FLAG
	IF
		DROP
		1
	THEN 
	THEN ;
	
: LCD_HANDLE					( -- )
	CURRENT_VALUE @ 			\ Handles display behavior
	DUP 10 =			 	\ ASCII Values less than 32 are control characters so we use 4 of them for the display functions we wish to implement
	IF					
		CLEAR_DISPLAY			\ Clears the display
	ELSE
	DUP 11 =
	IF
		DISPLAY_LSHIFT			\ Shifts the display to the left
	ELSE
	DUP 12 =
	IF
		DISPLAY_RSHIFT			\ Shifts the display to the right
	ELSE
	DUP 13 =
	IF
		FIRST_LINE			\ Sets the cursor position counter to the first position of the first line without easing RAM data
	ELSE
	DUP 14 =
	IF	
		SECOND_LINE			\ Sets the cursor position counter to the first position of the second line without easing RAM data
	ELSE
		DUP DISPLAY_CHAR		\ Displays the character, but avoids sending it to memory cells not shown on the 16x02 display
	THEN
	THEN
	THEN 
	THEN
	THEN 
	DROP ;
	
: WELCOME					( -- )
	57 DISPLAY_CHAR				\ Displays word WELCOME
	45 DISPLAY_CHAR				\ We send all the characters of the word we wish to display at power on
	4C DISPLAY_CHAR
	43 DISPLAY_CHAR
	4F DISPLAY_CHAR
	4D DISPLAY_CHAR
	45 DISPLAY_CHAR 
	21 DISPLAY_CHAR	
	SECOND_LINE				\ We wish to display the second word in the second line
	DISPLAY_RSHIFT				\ And we shift right from the start of the line
	76 DISPLAY_CHAR
	30 DISPLAY_CHAR
	2E DISPLAY_CHAR
	31 DISPLAY_CHAR
	1D0900 WAIT				\ We wait for the given time (in microseconds, hex value)
	CLEAR_DISPLAY ;				\ We clear the display, set the cursor to the start of the first line and reset the LINE_COUNTER
	
: INPUT						( -- )
	BEGIN 					
		BUTTONS SIZE @ LSHIFT			\ Left shifts the value on the stack by size places 
		CURRENT_VALUE @ + CURRENT_VALUE ! 	\ Adds the shifted value to the CURRENT_VALUE
		SIZE @ 1 + DUP SIZE !			\ Adds 1 to SIZE
		CLEAR_STATUS				\ Clears the STATUS register
		SIZE_REQUESTED MOD 0 =			\ If size is a multiple of 8 (so we put 8 bits on the stack)
		IF
			LCD_HANDLE			\ Call the LCD handler
			0 CURRENT_VALUE !		\ Resets the current value
			0 SIZE ! 			\ Resets the size
		THEN
	AGAIN ;
	
: START						( -- )
	SETUP					\ Starts the whole program
	LCD_INIT
	WELCOME
	INPUT ;

\ START



