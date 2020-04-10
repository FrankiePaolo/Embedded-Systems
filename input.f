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
	IF					\ Leaves on the stack either 0 or 1
		DROP				\ We make sure not to leave the GPEDS0 content on the stack
		0 
	ELSE
	DUP 200 AND BIT_FLAG
	IF
		DROP
		1
	THEN 
	THEN ;
	
: LCD_HANDLE					( -- )
	CURRENT_VALUE @ 			\ Handles display behavior
	DUP 10 =			 	\ ASCII Values less than 32 are control characters so we use them for the display functions
	IF					
		CLEAR_DISPLAY
	ELSE
	DUP 11 =
	IF
		DISPLAY_LSHIFT
	ELSE
	DUP 12 =
	IF
		DISPLAY_RSHIFT
	ELSE
	DUP 13 =
	IF
		FIRST_LINE
	ELSE
	DUP 14 =
	IF
		SECOND_LINE
	ELSE
		DUP SEND_CHAR
	THEN
	THEN
	THEN 
	THEN
	THEN 
	DROP ;
	
: WELCOME					( -- )
	57 SEND_CHAR				\ Displays word WELCOME
	45 SEND_CHAR
	4C SEND_CHAR
	43 SEND_CHAR
	4F SEND_CHAR
	4D SEND_CHAR
	45 SEND_CHAR 
	21 SEND_CHAR
	SECOND_LINE
	DISPLAY_RSHIFT
	76 SEND_CHAR
	30 SEND_CHAR
	2E SEND_CHAR
	31 SEND_CHAR
	1D0900 WAIT
	CLEAR_DISPLAY ;
	
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



