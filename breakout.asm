################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Assembled in EMARS 4.7
#
# Student 1: Brian Chen, 1008157879
# Student 2: John Fitzgerald, 1008155513
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    512
# - Display height in pixels:   512
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
COLOURS: 
	.word 0xe6261f	#red (0)
	.word 0xeb7532	#orange (4)
	.word 0xf7d038	#yellow (8)
	.word 0xa3e048	#green (12)
	.word 0x49da9a	#jade (16)
	.word 0x34bbe6	#sky (20)
	.word 0x4355db	#blue (24)
	.word 0xd23be7 #lean (28)
	.word 0x000000	#black (32)
	.word 0xfffdd0	#cream (36)
	.word 0x2a9d8f	#jungle (40)
	
LEVEL_TWO:
	.word 0xe6261f	#red (0)
	.word 0x000000	#black (4)
	.word 0xf7d038	#yellow (8)
	.word 0x000000	#black (12)
	.word 0x49da9a	#jade (16)
	.word 0x000000	#black (20)
	.word 0x4355db	#blue (24)
	
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
START_TIME:
    .space 8

##############################################################################
# Mutable Data
##############################################################################
BALL:
	.space 8	#reserve space for x and y coords of ball
	.space 8	#reserve space for x and y direction of ball
			# x direction is -1 for left, 1 for right
			# y direction is -1 for up, 1 for down
	.space 4	#reserve space for speed of ball
	.space 4	#reserve space for colour of ball

PADDLE:
	.space 4	#reserve space for x coord of paddle

BRICK_ARRAY:
	.space 56
	.space 56
	.space 56
	.space 56
	.space 56
	.space 56
	.space 56
SCORE:
	.word 0		#store current score, initialized to 0
	
LIVES:
	.word 3		# keep track of the players lives, intialized to 3
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    
    la $t0, PADDLE
    addi $t1, $0, 30
    sw, $t1, 0($t0)
	
    # Load current time into constant
    
    la $t0, START_TIME
    li $v0, 30
    syscall
    sw, $a0, 0($t0)
    	
    # initialize ball with starting position and direction
    la $t0, BALL
    addi $t1, $0, 31
    sw, $t1, 0($t0)
    addi $t1, $0, 54
    sw $t1, 4($t0)
    addi $t1, $0, -1
    sw, $t1, 8($t0)
    addi $t1, $0, -1
    sw $t1, 12($t0)
    
    la $a0, COLOURS
    jal populate_bricks
    jal draw_walls
    jal draw_bricks
    jal draw_paddle
    jal draw_ball
    
    j game_loop
    

# subtract 1 life, if the player has 1 or more lives, let them play again
check_lives:
	la $t0, LIVES			# get address for lives
	lw $t1, 0($t0)			# store the lives in $t1
	addi $t1, $t1, -1		# subtract lives by 1 and store in $t1
	sw $t1, 0($t0) 			# store the new lives count in memory
	ble $t1, 0, game_over		# if there are 0 lives, the game is over
	# intialize ball again
	la $t0, BALL
    	addi $t1, $0, 31
   	sw, $t1, 0($t0)
    	addi $t1, $0, 54
   	sw $t1, 4($t0)
  	addi $t1, $0, -1
   	sw, $t1, 8($t0)
   	addi $t1, $0, -1
   	sw $t1, 12($t0)
   	
   	j game_loop


# the ball went out of bounds and the game is over   
game_over:
	jal reset_screen
	
	# check for keyboard input 'r' to restart or 'q' to quit
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    	lw $t8, 0($t0)                  # Load first word from keyboard
    	beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    	
    	# sleep
    	li $v0, 32
	li $a0, 50
	syscall
	# wait for key press again
	b game_over

# time limit reached
time_limit:
	
	la $t0, LIVES			# get address for lives
	addi $t1, $0, 0			# store 0 in t1
	sw $t1, 0($t0)			# set lives to 0
	
	b detect_collision		# branch to collision detection
	
	

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 63, inclusive
#       - y is between 0 and 63, inclusive
get_location_address:
	# BODY
	sll $a0, $a0, 2 # x_bytes = x * 4
	sll $a1, $a1, 8 # y_bytes = y * 256
	
	la $v0, ADDR_DSPL
	lw $v0, 0($v0)
	add $v0, $a0, $v0
	add $v0, $a1, $v0 # loc_address = base_address + x_bytes + y_bytes
	
	
	# EPILOGUE
	jr $ra
	
	
	
# get_brick_address(x, y) -> address, (x_start, y_start) [on stack]
#   Return the address of the brick from the BRICK_ARRAY in memory
#
#   Preconditions:
#       - x is between 4 and 59, inclusive
#       - y is between 9 and 22, inclusive
# arr_x = pos_x // 4 - 1
# arr_y = (pos_x - 9) // 2	
# the brick address is going to be the ith element in BRICK_ARRAY 
# where i = arr_x + arr_y * 56
# e.g. the first brick in the second row (from the top) will have x_arr = 0, y_arr = 1,
# so it will be the 14th element in BRICK_ARRAY (14th element x 4 = 56)
get_brick_address:
	# BODY	
	subi $a0, $a0, 4	# subtract x by 4 (to get proper index when floor dividing)
	div $a0, $a0, 4		# floor divide x by 4
	addi $t0, $a0, 0 	# store $a0 in $t0 ($a0 is the index for brick array)
	
	sll $t0, $t0, 2		# multiply by 4 -> the x starting position of brick
	
	
	addi $t0, $t0, 4		# add 4 to account for offset 
	
	addi $sp, $sp,  -4	# store starting x positions on stack
	sw $t0, 0($sp)
	
	subi $a1, $a1, 11	# subtract y by 11 (to get proper index when floor dividing)
	div $a1, $a1, 2		# floor divide y by 2
	addi $t1, $a1, 0 	# store $a1 in $t1 ($a1 is the index for brick array)
	
	sll $t1, $t1, 1		# multiply by 2 -> the y starting position of brick
	
	
	addi $t1, $t1, 11		# add 11 to account for offset
	
	addi $sp, $sp, -4   	# store starting y position on stack
	sw $t1, 0($sp)
	
	sll $a0, $a0, 2		# multiply x index by 4 to represent index in terms of words 
	li  $t1, 56		# multiply by 56
	mult $a1, $t1
	mflo $a1
	
	add $t0, $a0, $a1 	# the index of the brick in BRICK_ARRAY
	
	la $v0, BRICK_ARRAY
	add $v0, $v0, $t0	# return the position of the brick in BRICK_ARRAY
	
	# EPILOGUE
	jr $ra



# populate_bricks(COLOUR_ARRAY_ADDRESS) -> void
# 	Populate the brick array with the starting colours
populate_bricks:
	# PROLOGUE
   	addi $sp, $sp, -20
    	sw $s3, 16($sp)
   	sw $s2, 12($sp)
    	sw $s1, 8($sp)
   	sw $s0, 4($sp)
    	sw $ra, 0($sp)

	addi $s0, $a0, 0		# load location for colours
	la $s1, BRICK_ARRAY    		# load location for BRICK_ARRAY
	li $s2, 7
# Iterate 7 ($s2) times
    	li $s3, 0                   # i = 0
populate_bricks_loop:
	slt $t2, $s3, $s2           # i < end ?
    	beq $t2, $0, populate_bricks_epi # if not, then done
		
		lw $a0, 0($s0)
		addi $a1, $s1, 0
        	jal populate_bricks_row
        	addi $s0, $s0, 4
        	addi $s1, $s1, 56

    addi $s3, $s3, 1            # i = i + 1
    j populate_bricks_loop	
    
populate_bricks_epi:
    
   	 # EPILOGUE
    
   	lw $ra, 0($sp)
   	lw $s0, 4($sp)
   	lw $s1, 8($sp)
   	lw $s2, 12($sp)
    	lw $s3, 16($sp)
   	addi $sp, $sp, 20
    
   	jr $ra   
    
# populate_bricks_row(COLOUR VALUE, START_ADDRESS) -> void
# 	Called by populate_bricks to do one row at a time
populate_bricks_row:
	li $t0, 0 		# i = 0
	li $t7, 14		# end = 14
	
populate_bricks_row_loop:
    slt $t2, $t0, $t7           # i < end ?
    beq $t2, $0, populate_bricks_row_epi # if not, then done

        sw $a0, 0($a1)		# store the colour
        addi $a1, $a1, 4		# increment address by 4 bytes

    addi $t0, $t0, 1            # i = i + 1
    j populate_bricks_row_loop	
	 
populate_bricks_row_epi:
	jr $ra    

# reset_screen(-> void
#   Draw the screen with black
reset_screen:
	# PROLOGUE
	addi $sp, $sp, -20
    	sw $s3, 16($sp)
    	sw $s2, 12($sp)
    	sw $s1, 8($sp)
    	sw $s0, 4($sp)
	sw $ra, 0($sp)

    # BODY
    la $s0, ADDR_DSPL
    lw $s0, 0($s0) 		# initialize the start location 
    la $s1, COLOURS
    addi $s1, $s1, 32		# load colour black address
    li $s2, 64			# size

    # Iterate 64 ($s2) times, drawing each line
    li $s3, 0                   # i = 0
reset_screen_loop:
    slt $t0, $s3, $s2           # i < 64 ?
    beq $t0, $0, reset_screen_epi# if not, then done

        # call draw_line
        addi $a0, $s0, 0 	# starting address for draw line
        addi $a1, $s1, 0
        addi $a2, $s2, 0
        jal draw_line

        addi $s0, $s0, 256     # Go to next row

    addi $s3, $s3, 1            # i = i + 1
    b reset_screen_loop

reset_screen_epi:
    	# EPILOGUE
	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	lw $s3, 16($sp)
	addi $sp, $sp, 20

    	jr $ra





# erase_brick(start) -> void
#   Erase a brick on the display starting from the start address
#
#   Preconditions:
#       - The start address can "accommodate" a brick of size 2 x 4
erase_brick:
    
    # PROLOGUE
    addi $sp, $sp, -20
    sw $s3, 16($sp)
    sw $s2, 12($sp)
    sw $s1, 8($sp)
    sw $s0, 4($sp)
    sw $ra, 0($sp)
	
    
    # BODY
    # Arguments are not preserved across function calls, so we
    # save them before starting the loop
    addi $s0, $a0, 0
    la $s1, COLOURS
    lw $s1, 0($s1)
    li $s2, 2
    

    # Iterate 2 ($s2) times, drawing each line
    li $s3, 0                   # i = 0
erase_brick_loop:
    slt $t0, $s3, $s2           # i < size ?
    beq $t0, $0, erase_brick_epi# if not, then done

        # call draw_line
        addi $a0, $s0, 0 # start
        
        la $a1, COLOURS
        add $a1, $a1, 32 #colour_address
        
        li $a2, 4	  # width = 4
        jal draw_line

        addi $s0, $s0, 256      # Go to next row

    addi $s3, $s3, 1            # i = i + 1
    b erase_brick_loop


				
    
    
    
erase_brick_epi:

    li $v0, 31					# play sound
    li $a0, 18
    li $a1, 100
    li $a2, 15
    li $a3, 100
    syscall
    
    # EPILOGUE
    
    lw	    $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
    addi    $sp, $sp, 20
    
    

    jr $ra



# draw_line(start, colour_address, width) -> void
#   Draw a line with width units horizontally across the display using the
#   colour at colour_address and starting from the start address.
#
#   Preconditions:
#       - The start address can "accommodate" a line of width units
draw_line:
    # Retrieve the colour
    lw $t0, 0($a1)              # colour = *colour_address

    # Iterate $a2 times, drawing each unit in the line
    li $t1, 0                   # i = 0
draw_line_loop:
    slt $t2, $t1, $a2           # i < width ?
    beq $t2, $0, draw_line_epi  # if not, then done

        sw $t0, 0($a0)          # Paint unit with colour
        addi $a0, $a0, 4        # Go to next unit

    addi $t1, $t1, 1            # i = i + 1
    j draw_line_loop

draw_line_epi:
    jr $ra

# draw_walls()
#   Draw the walls of the breakout game on the display
#
draw_walls:
	
	#PROLOGUE
	addi $sp, $sp, -16
	sw $s2, 12($sp)
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)



		# draw top wall (4 lines from x = 4 -> x = 59) 
	li $a0, 4 # x_value
	li $a1, 0 # y_value
	jal get_location_address # returns loc_address in $v0
	
	add $a0, $v0, $0 # store starting location for first 
	addi $s2, $a0, 0
	
	la $a1, COLOURS
	addi $a1, $a1, 36 # set colour address for border colour
	
	li $a2, 56 # draw line 56 units wide
	
	
	li $s0, 0	# i = 0
	li $s1, 4	
draw_top_wall_loop:
	slt $t1, $s0, $s1	# i < 4
	beq $t1, $0, draw_left_wall
	
		addi $a0, $s2, 0
		jal draw_line
		addi $s2, $s2, 256 	# go to next row (512/8 pixels per unit = 64 units * 4 bytes per unit = 256)
	
	addi $s0, $s0, 1	# i = i + 1
	j draw_top_wall_loop
		
draw_left_wall:
	la $a0, ADDR_DSPL 	# store starting location for first
	lw $a0, 0($a0)
	addi $s2, $a0, 0	
	
	la $a1, COLOURS
	addi $a1, $a1, 36 	# set colour address for border colour
	
	li $a2, 4 	# draw line 4 units wide
	
	li $s0, 0	# i = 0
	li $s1, 64
	
	
draw_left_wall_loop:
	slt $t1, $s0, $s1	# i < 64
	beq $t1, $0, draw_right_wall
		
		addi $a0, $s2, 0
		jal draw_line
		addi $s2, $s2, 256	# go to next row (512/8 pixels per unit = 64 units * 4 bytes per unit = 256)
	
	addi $s0, $s0, 1	# i = i + 1
	j draw_left_wall_loop
	
draw_right_wall:
	li $a0, 60 # x_value
	li $a1, 0 # y_value
	jal get_location_address # returns loc_address in $v0
	
	add $a0, $v0, $0 # store starting location for first 
	addi $s2, $a0, 0	
	
	la $a1, COLOURS
	addi $a1, $a1, 36 	# set colour address for border colour
	
	li $a2, 4 	# draw line 4 units wide
	
	li $s0, 0	# i = 0
	li $s1, 64
draw_right_wall_loop:
	slt $t1, $s0, $s1	# i < 64
	beq $t1, $0, draw_wall_epi
		
		addi $a0, $s2, 0
		jal draw_line
		addi $s2, $s2, 256	# go to next row (512/8 pixels per unit = 64 units * 4 bytes per unit = 256)
	
	addi $s0, $s0, 1	# i = i + 1
	j draw_right_wall_loop

draw_wall_epi:
	#EPILOGUE
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw, $s1, 8($sp)
	lw, $s2, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra
	
# draw_bricks()
#   Draw the bricks of the breakout game on the display
#
draw_bricks:
	#PROLOGUE
	addi $sp, $sp, -16
	sw $s2, 12($sp)
	sw $s1, 8($sp)
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	li $a0, 4 # x_value
	li $a1, 11 # y_value
	jal get_location_address # returns loc_address in $v0
	
	add $a0, $v0, $0 # store starting location for first 
	addi $s2, $a0, 0
	
	
	
	li $a2, 4 # draw line 4 units wide
	
	
	li $s0, 0	# i = 0
	li $s1, 392	# 98 bricks x 4 bytes to get to next brick = 392
draw_brick_loop:
	slt $t1, $s0, $s1	# i < 64
	beq $t1, $0, draw_bricks_epi
	
		la $a1, BRICK_ARRAY	# get colour of brick from array
		add $a1, $a1, $s0
		
		li $a2, 4 	# draw line 4 units wide
		
		addi $a0, $s2, 0
		jal draw_line
		
		la $a1, BRICK_ARRAY	# get colour of brick from array
		add $a1, $a1, $s0
		
		li $a2, 4 	# draw line 4 units wide
		
		addi $s2, $s2, 256	# go to next row
		addi $a0, $s2, 0
		jal draw_line
		
		subi $s2, $s2, 256
		addi $s2, $s2, 16	# go to next column
	
	addi $s0, $s0, 4	# i = i + 4
	
	addi $t3, $0, 56	# once end of row is reached (56 units), go to next row
	div $s0, $t3
	mfhi $t4
	beq $t4, $0, draw_bricks_next_row
	j draw_brick_loop
draw_bricks_next_row:
	addi $s2, $s2, 288	# go to next row (+ 2 lines)	
	j draw_brick_loop
		
draw_bricks_epi:
	#EPILOGUE
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw, $s1, 8($sp)
	lw, $s2, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra

# draw_paddle(erase)
#   Draw a paddle on the display at position (x, 56). If erase
#   is 1, draw paddle in black
draw_paddle:
	#PROLOGUE
	addi $sp, $sp, -8
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	addi $s0, $a0, 0	# store erase value
	
	la $a0, PADDLE
	lw $a0, 0($a0)
	
	li $a1, 55	# set y to 55
	jal get_location_address	# returns loc_address in $v0
	add $a0, $v0, $0
	
	beq $s0, 1, erase_paddle
	la $a1, COLOURS
	addi $a1, $a1, 28 	# set colour address for paddle colour
	b draw_paddle_cont
	
erase_paddle:
	la $a1, COLOURS
	addi $a1, $a1, 32	

draw_paddle_cont:	
	li $a2, 8	# paddle 8 units wide
	
	jal draw_line
	
	
	#EPILOGUE
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 4
	
	jr $ra

# draw_ball(erase)
#   Draw the ball on the display. If erase is 1, draw ball in black.
#
draw_ball:
	# PROLOGUE
	addi $sp, $sp, -8
	sw $s0, 4($sp)
	sw $ra, 0($sp)
	
	addi $s0, $a0, 0	# store erase value
	
	la $t0, BALL
	lw $a0, 0($t0)		# get x from ball
	lw $a1, 4($t0)		# get y from ball
	
	jal get_location_address
	
	beq $s0, 1, erase_ball
	la $t1, COLOURS		# get colour of ball
	addi $t1, $t1, 40
	lw $t1, 0($t1)
	b draw_ball_cont
erase_ball:
	la $t1, COLOURS		# make ball black
	addi $t1, $t1, 32
	lw $t1, 0($t1)
	
draw_ball_cont:
	sw $t1, 0($v0)		# draw ball at unit
	
	# EPILOGUE
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra
game_loop:
	li $v0, 30			# load current time
	syscall
	la $t3, START_TIME		# check if current time has reached start time +30000 ms
	lw $t4, 0($t3)			

	addi $t4, $t4, 30000
	bgt $a0, $t4, time_limit	# if so, end game

	
	la $t0, SCORE			# check if all bricks have been broken, if so, end game
	lw $t1, 0($t0)
	beq $t1, 98, game_over
					
	
	# 1a. Check if key has been pressed
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    	lw $t8, 0($t0)                  # Load first word from keyboard
    	beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    	
    	b detect_collision

pause_loop:
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
	lw $t8, 0($t0)                  # Load first word from keyboard
    	beq $t8, 1, check_resume	# If first word 1, key is pressed
    	
    	b pause_loop

check_resume:				# A key is pressed
	lw $a0, 4($t0)                  # Load second word from keyboard COMMENT THIS OUT TO MOVE ONE FRAME AT A TIME FOR DEBUG
	beq $a0, 0x70, detect_collision	# if P is pressed, resume game
	b pause_loop			# else, go back to pause loop

    # 1b. Check which key has been pressed
keyboard_input:                     # A key is pressed
    	lw $a0, 4($t0)                  # Load second word from keyboard
    	beq $a0, 0x71, respond_to_Q     # Check if an action key was pressed
    	beq $a0, 0x61, respond_to_A
	beq $a0, 0x64, respond_to_D
	beq $a0, 0x72, respond_to_R
	beq $a0, 0x70, respond_to_P
	beq $a0, 0x32, respond_to_2
	
    	li $v0, 1                       # ask system to print $a0
    	syscall

    	b detect_collision

respond_to_2:
	jal reset_screen
	
	# reset lives (level 2 only gets 1 life)
	la $t0, LIVES
	li $t1, 1
	sw $t1, 0($t0)
	
	# Initialize the game
    
    	la $t0, PADDLE
    	addi $t1, $0, 30
    	sw, $t1, 0($t0)
	
    	# Load current time into constant
    
    	la $t0, START_TIME
    	li $v0, 30
    	syscall
    	sw, $a0, 0($t0)
    	
    	# initialize ball with starting position and direction
    	la $t0, BALL
    	addi $t1, $0, 31
    	sw, $t1, 0($t0)
    	addi $t1, $0, 54
    	sw $t1, 4($t0)
    	addi $t1, $0, -1
    	sw, $t1, 8($t0)
    	addi $t1, $0, -1
    	sw $t1, 12($t0)
    
    	la $a0, LEVEL_TWO
    	jal populate_bricks
    	jal draw_walls
    	jal draw_bricks
    	jal draw_paddle
    	jal draw_ball
    
    	j game_loop
	

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
respond_to_R:
	# reset lives
	la $t0, LIVES
	li $t1, 3
	sw $t1, 0($t0)

	# reset paddle line
	li $a0, 4
	li $a1, 55
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, COLOURS
	addi $a1, $a1, 32
	li $a2, 56
	jal draw_line
	# reset previous balls
	li $a0, 4
	li $a1, 63
	jal get_location_address
	addi $a0, $v0, 0
	la $a1, COLOURS
	addi $a1, $a1, 32
	li $a2, 56
	jal draw_line
	# call main again and restart game
	j main

respond_to_P:
	b pause_loop 			# If p is pressed, go to paused loop of game
	
	
    # 2a. Check for collisions
detect_collision:
	#PROLOGUE
		addi $sp, $sp, -16
		sw $s3, 12($sp)
		sw $s2, 8($sp)
		sw $s1, 4($sp)
		sw $s0, 0($sp)
	
	# $s0 = x, $s1 = y, $s2 = x direction, $s3 = y direction
	la $t0, BALL
	lw $s0, 0($t0)	# get x value from ball
	lw $s1, 4($t0)	# get y value from ball
	lw $s2, 8($t0)	# get x direction
	lw $s3, 12($t0)	# get y direction
	
	add $t0, $s0, $s2 # x_next
	add $t1, $s1, $s3 # y_next
	ble $t0, 3, check_walls		# possible collision with left wall
	bge $t0, 60, check_walls	# possibile collision with right wall
	beq $t1, 55, paddle_collision	# possible collision with paddle
	bge $s1, 63, check_lives	# ball out of bounds
	ble $t1, 10, check_walls	# possible collision with top wall
	bge $t1, 25, check_walls  	# possible collision with something other than bricks

	
	# check if x_next and y_next are within brick bounds
	# ble $t1, 10, detect_collision_epi
	# bge $t1, 23, detect_collision_epi
	
	
	# x_next is between 4 and 59 inclusive and y_next is between 11 and 24 inclusive
	# check for brick collision (3 conditions)
		# check if ball next position is occupied by a brick using get_brick_address
		brick_collision_1:
		# condition 1: hit top/bottom of brick -> delete and invert y direction
			# moving vertically results in a collision
			addi $a0, $s0, 0 	# load x
			add $t1, $s1, $s3 	# y_next
			addi $a1, $t1, 0	# load y_next
			jal get_brick_address
			lw $a1, 0($sp)		# starting y of brick in units
			lw $a0, 4($sp)		# starting x of brick in units
			addi $sp, $sp, 8
			addi $t0, $v0, 0	# memory location of brick in BRICK_ARRAY
			lw $v0, 0($v0)		# colour value of the brick
			# if colour at this location isn't 0x000000, erase brick and invert y
			beq $v0, 0, brick_collision_2# no brick present
			la $t1, COLOURS		# get memory location of COLOURS
			lw $t1, 32($t1)		# value of colour black
			sw $t1, 0($t0)		# set the BRICK colour to black
			jal get_location_address
			addi $a0, $v0, 0
			jal erase_brick 	# erase the brick with the collision
			
			# increment score
    			jal increment_score
	
			# invert y direction
			addi $t3, $s3, 0	# store value of y direction in temp
			sub $s3, $s3, $t3	# simulate negation by subtracting by itself twice
			sub $s3, $s3, $t3
			la $t0, BALL
			sw $s3, 12($t0) 	# update y direction
			b detect_collision_epi
			
		brick_collision_2:
		# condition 2: hit side of brick -> delete and invert x direction
			# moving horizontally results in a collision
			addi $a1, $s1, 0 	# load y
			add $t1, $s0, $s2 	# x_next
			addi $a0, $t1, 0	# load x_next
			jal get_brick_address
			lw $a1, 0($sp)		# starting y of brick in units
			lw $a0, 4($sp)		# starting x of brick in units
			addi $sp, $sp, 8
			addi $t0, $v0, 0	# memory location of brick in BRICK_ARRAY
			lw $v0, 0($v0)		# colour value of the brick
			# if colour at this location isn't 0x000000, erase brick and invert y
			beq $v0, 0, brick_collision_3	# no brick present
			la $t1, COLOURS		# get memory location of COLOURS
			lw $t1, 32($t1)		# value of colour black
			sw $t1, 0($t0)		# set the BRICK colour to black
			jal get_location_address
			addi $a0, $v0, 0
			jal erase_brick 	# erase the brick with the collision
			
			# increment score
    			jal increment_score
    			
			# invert x direction
			addi $t2, $s2, 0	# store value of x direction in temp
			sub $s2, $s2, $t2		# simulate negation by subtracting by itself twice
			sub $s2, $s2, $t2	
	
			la $t0, BALL
			sw $s2, 8($t0) 		# update x direction
			b detect_collision_epi
			
		brick_collision_3:
		# condition 3: hit corner of brick -> delete and invert both directions
			# moving in both axes results in a collision
			add $t0, $s0, $s2	# x_next
			addi $a0, $t0, 0 	# load x_next
			add $t1, $s1, $s3 	# y_next
			addi $a1, $t1, 0	# load y_next
			jal get_brick_address
			lw $a1, 0($sp)		# starting y of brick in units
			lw $a0, 4($sp)		# starting x of brick in units
			addi $sp, $sp, 8
			addi $t0, $v0, 0	# memory location of brick in BRICK_ARRAY
			lw $v0, 0($v0)		# colour value of the brick
			# if colour at this location isn't 0x000000, erase brick and invert y
			beq $v0, 0, check_walls	# no brick present
			la $t1, COLOURS		# get memory location of COLOURS
			lw $t1, 32($t1)		# value of colour black
			sw $t1, 0($t0)		# set the BRICK colour to black
			jal get_location_address
			addi $a0, $v0, 0
			jal erase_brick 	# erase the brick with the collision
			
			# increment score
    			jal increment_score
	
			# invert x direction
			addi $t2, $s2, 0	# store value of x direction in temp
			sub $s2, $s2, $t2	# simulate negation by subtracting by itself twice
			sub $s2, $s2, $t2	
	
			# invert y direction
			addi $t3, $s3, 0	# store value of y direction in temp
			sub $s3, $s3, $t3	# simulate negation by subtracting by itself twice
			sub $s3, $s3, $t3
	
			la $t0, BALL
			sw $s2, 8($t0) 		# update x direction
			sw $s3, 12($t0) 	# update y direction
			b detect_collision_epi
		
	check_walls:	
	add $t0, $s0, $s2 		# check x left out of bounds
	ble $t0, 3, corner_collision 	# branch to corner collision
	bge $t0, 60, corner_collision	# check x right out of bounds
					# branch to corner collision
	add $t0, $s1, $s3		# check y out of bounds
	ble $t0, 3, top_wall_collision # branch to top wall collision
	b detect_collision_epi
	
	top_wall_collision:
	
	li $v0, 31					# play sound
      	li $a0, 10
      	li $a1, 100
      	li $a2, 9
      	li $a3, 100
      	syscall
	
	# invert y direction
	addi $t3, $s3, 0		# store value of y direction in temp
	sub $s3, $s3, $t3		# simulate negation by subtracting by itself twice
	sub $s3, $s3, $t3
	la $t0, BALL
	sw $s3, 12($t0)
	b detect_collision_epi
	
	
	wall_collision:
	li $v0, 31					# play sound
      	li $a0, 10
      	li $a1, 100
      	li $a2, 9
      	li $a3, 100
      	syscall
	
	# invert x direction
	addi $t2, $s2, 0		# store value of x direction in temp
	sub $s2, $s2, $t2		# simulate negation by subtracting by itself twice
	sub $s2, $s2, $t2
	la $t0, BALL
	sw $s2, 8($t0) 			# update x direction
	sw $s3, 12($t0) 		# update y direction
	b detect_collision_epi
	
	corner_collision:
	add $t0, $s1, $s3 		# y + y direction
	bge $t0, 4, wall_collision 	# check y in bounds
				   	# if y in bounds, branch to wall
	# invert x direction
	addi $t2, $s2, 0		# store value of x direction in temp
	sub $s2, $s2, $t2		# simulate negation by subtracting by itself twice
	sub $s2, $s2, $t2	
	
	# invert y direction
	addi $t3, $s3, 0		# store value of y direction in temp
	sub $s3, $s3, $t3		# simulate negation by subtracting by itself twice
	sub $s3, $s3, $t3
	
	la $t0, BALL
	sw $s2, 8($t0) 			# update x direction
	sw $s3, 12($t0) 		# update y direction
	b detect_collision_epi
		
	
	paddle_collision:
	add $t0, $s0, $s2 # x_next
	add $t1, $s1, $s3 # y_next
	# get paddle position (leftmost unit)
	la $t2, PADDLE 		# get address of PADDLE in memory
	lw $t2, 0($t2)		# $t2 = leftmost x value of paddle
	addi $t2, $t2, -1	# $t2 = $t2 - 1
	sgt $t1, $t0, $t2
	addi $t2, $t2, 10	# t2 = rightmost x value of paddle + 1
      	slt $t4, $t0, $t2	
      	add $t4, $t4, $t1
      	bne $t4, 2, detect_collision_epi	# if $t4 is two, then the ball will collide with the paddle
      	

      	li $v0, 31					# play sound
      	li $a0, 32
      	li $a1, 100
      	li $a2, 5
      	li $a3, 100
      	syscall

      	
      	
      	
      	
      	add $t0, $s0, $s2 	# x_next
      	la $t2, PADDLE 		# get address of PADDLE in memory
	lw $t2, 0($t2)		# $t2 = leftmost x value of paddle
	sub $t6, $t0, $t2 	# check distance between x_next and start position of paddle
	ble $t6, 1, paddle_edge_collision
	bge $t6, 6, paddle_edge_collision
	# invert y direction
	addi $t3, $s3, 0	# store value of y direction in temp
	sub $s3, $s3, $t3	# simulate negation by subtracting by itself twice
	sub $s3, $s3, $t3
	la $t0, BALL
	sw $s3, 12($t0) 	# update y direction
	b detect_collision_epi
	
	
      	paddle_edge_collision:
      	# invert x and y directions
      	# invert x direction
	addi $t2, $s2, 0	# store value of x direction in temp
	sub $s2, $s2, $t2	# simulate negation by subtracting by itself twice
	sub $s2, $s2, $t2	
	
	# invert y direction
	addi $t3, $s3, 0	# store value of y direction in temp
	sub $s3, $s3, $t3	# simulate negation by subtracting by itself twice
	sub $s3, $s3, $t3
	
	la $t0, BALL
	sw $s2, 8($t0) 		# update x direction
	sw $s3, 12($t0) 	# update y direction
	
	# EPILOGUE
	detect_collision_epi:
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		sw $s3, 12($sp)
		addi $sp, $sp, 16
		b refresh_ball

# increment_score()
#	
#	increment score by 1 on brick collision
increment_score:
	
	la $t0, SCORE		
	lw $t1, 0($t0)		# get current score
	addi $t1, $t1, 1	# increment score
	sw $t1, 0($t0)		# store score
	
	jr $ra			# return
	
	
respond_to_A:
	li $a0, 1
	jal draw_paddle		# erase paddle
	
	la $t0, PADDLE		# update paddle coord
	lw $t1, 0($t0)
	
	beq $t1, 4, paddle_max_left
	subi $t1, $t1, 2	# shift paddle 2 units left	
	sw $t1, 0($t0)

paddle_max_left:
	b refresh_paddle
	
respond_to_D:
	li $a0, 1
	jal draw_paddle		# erase paddle
	
	la $t0, PADDLE		# update paddle coord
	lw $t1, 0($t0)
	
	beq $t1, 52, paddle_max_right
	addi $t1, $t1, 2	# shift paddle 2 units right	
	sw $t1, 0($t0)
paddle_max_right:
	
	b refresh_paddle
	
	# 3. Draw the screen
refresh_paddle:
	
	li $a0, 0
	jal draw_paddle
	
	b detect_collision

refresh_ball:
	
	li $a0, 1		# erase ball
	jal draw_ball
	
	la $t0, BALL
	lw $t1, 0($t0)		# get x from ball
	lw $t2, 4($t0)		# get y from ball
	lw $t3, 8($t0)		# get x direction from ball
	lw $t4, 12($t0)		# get y direction from ball
	
	add $t1, $t1, $t3	# update coords (x + x direction)
	add $t2, $t2, $t4	# (y + y direction)
	sw $t1, 0($t0)		# store the updated coords of the ball into memory
	sw $t2, 4($t0)
	
	li $a0, 0
	jal draw_ball
	
	#li $v0, 32
	#li $a0, 25
	#syscall
	
	
	# tell display to update
	lw   $t8, ADDR_DSPL
	la $t9, COLOURS
	lw $t9, 36($t9)
	sw $t9, 0($t8)
	
	b sleep
	
	
	
    	
	# 4. Sleep
sleep:
	li $v0, 32
	li $a0, 30
	syscall
	
	#5. Go back to 1
    	b game_loop
