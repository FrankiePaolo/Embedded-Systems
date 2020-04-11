CREATE USER_FUNCTIONS ' CLEAR_DISPLAY , ' DISPLAY_LSHIFT , ' DISPLAY_RSHIFT , ' FIRST_LINE , ' LAST_FIRST_LINE , ' SECOND_LINE , ' LAST_SECOND_LINE ,
\ We create a dictionary entry with the execution tokens of the various user functions

VARIABLE 							 CURRENT_VALUE
VARIABLE 							 SIZE 
8 							CONSTANT SIZE_REQUESTED 			\ Size of display command ( in our instance it's a byte , 8 bit ASCII )		



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
	400 CHECK		
	IF					
		DROP				\ We make sure not to leave the GPEDS0 content on the stack
		0 				\ Leaves on the stack either 0 or 1
	ELSE
	200 CHECK
	IF
		DROP
		1
	THEN 
	THEN ;

: USER_CHOICE 					( nth -- )
	CELLS USER_FUNCTIONS + @ EXECUTE ;	\ We execute the xt of the nth user function in USER_FUNCTIONS

: ?IS_VALID 					( CURRENT_VALUE )
	10 16 WITHIN ;				\ We check that the value is within the specified range

: LCD_HANDLE					( -- )
	CURRENT_VALUE @
	DUP ?IS_VALID 				\ Checks if CURRENT_VALUE is within the specified range
	IF					
		10 - USER_CHOICE		\ We subtract 10 so that we can choose the correct user function in the USER_FUNCTIONS table 
	ELSE
		DISPLAY_CHAR			\ If it's not a function it displays the character
	THEN ;
	
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



