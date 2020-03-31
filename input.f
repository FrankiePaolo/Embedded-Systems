VARIABLE CURRENT_VALUE

: APPEND 						( n1 n2  -- 2n2 + n1  )
	1 LSHIFT OR ;					\ n2 is always a single bit, so a more efficient OR operation is used in place of a sum

: FALLING_EDGE_DETECT_SET_9				( -- )
	GPFEN0 9 1 MASK_REGISTER OR GPFEN0 ! ;
	
: FALLING_EDGE_DETECT_SET_10				( -- )
	GPFEN0 10 1 MASK_REGISTER OR GPFEN0 ! ;

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



: GET_NUMBER				\ reads digits until a byte has been inputed 

	0 CURRENT_VALUE !
	0											\ initializes loop
	BEGIN
		>R 
		PEEK_KEYPRESS DUP
		?VALID					
		IF
			?DIGIT 
			IF 
				R> 1 + >R 
				READ_KEYPRESS KEY>DIGIT 
				CURRENT_VALUE @ APPEND 
				STORE_VALUE 
				RESULT SHOW
			ELSE 
				R> DROP WORD_SIZE >R		\ sets the loop termination condition
			THEN
		ELSE
			DROP 
		THEN 
		R> DUP WORD_SIZE >=				\ checks if all the bits have been set
	UNTIL 
	DROP ;



