VARIABLE CURRENT_VALUE
VARIABLE SIZE 
8 CONSTANT SIZE_REQUESTED



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

: CLEAR_PIN
	600 GPEDS0 ! ; 					\ We don't need to use a mask hence increase efficiency
	
: IS_PRESSED
	BEGIN
	GPEDS0 @ BIT_FLAG
	UNTIL ;

: READ_PIN						( -- 0/1 )	
	IS_PRESSED
	GPEDS0 @ 400 =					\ I	t leaves on the stack either 0 or 1
	IF
	0 
	THEN
	GPEDS0 @ 200 =
	IF
	1
	THEN ; 
	
: GET_INPUT						( -- )	
	BEGIN
		READ_PIN SIZE @ LSHIFT			\ Reads digits until a byte has been inputed 
		CURRENT_VALUE @ + CURRENT_VALUE ! 	
		SIZE @ 1 + DUP SIZE !
		CLEAR_PIN
	SIZE_REQUESTED =
	UNTIL ;


: SETUP
	SETUP_9
	SETUP_10
	SETUP_BSC
	FALLING_EDGE_DETECT_SET 
	0 CURRENT_VALUE !				
	0 SIZE ! ;					

