################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
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
	
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

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
	.word 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f
	.word 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532
	.word 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038,0xf7d038
	.word 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048
	.word 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a
	.word 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6
	.word 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    
    la $t0, PADDLE
    addi $t1, $0, 29
    sw, $t1, 0($t0)

    
    la $t0, BALL
    addi $t1, $0, 31
    sw, $t1, 0($t0)
    addi $t1, $0, 54
    sw $t1, 4($t0)
    addi $t1, $0, -1
    sw, $t1, 8($t0)
    addi $t1, $0, -1
    sw $t1, 12($t0)
    
    jal draw_walls
    jal draw_bricks
    jal draw_paddle
    jal draw_ball
    
    j game_loop
    
    




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
# where i = arr_x + arr_y * 64
# e.g. the first brick in the second row (from the top) will have x_arr = 0, y_arr = 1,
# so it will be the 64th element in BRICK_ARRAY
get_brick_address:
	# BODY
	srl $a0, $a0, 2 	# floor divide x by 4
	subi $a0, $a0, 1	# subtract x by 1
	addi $t0, $a0, 1 	# add 1
	sll $t0, $t0, 2  	# mult 2 -> the x starting position of brick
	addi $sp, $sp,  -4	# store starting x positions on stack
	lw $t0, 0($sp)
	
	subi $a1, $a1, 1	# subtract y by 1
	srl $a1, $a1, 1		# floor divide y by 2
	
	addi $t1, $a1, 0	# invert above steps
	sll $t1, $t1, 2
	addi $t1, $t1, 1 
	addi $sp, $sp, -4   		# store starting y position on stack
	lw $t0, 0($sp)
	sll $a1, $a1, 6 	# multiply by 64
	
	add $t0, $a0, $a1 	# the index of the brick in BRICK_ARRAY
	sll $t0, $t0, 2		# represent the index in terms of words (multiply by 4)
	
	
	la $v0, BRICK_ARRAY
	addi $v0, $t0, 0	# return the position of the brick in BRICK_ARRAY
	
	# EPILOGUE
	jr $ra

# erase_brick(start) -> void
#   Erase a brick on the display starting from the start address
#
#   Preconditions:
#       - The start address can "accommodate" a brick of size 4 x 2
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
    addi $s2, $s2, 2
    

    # Iterate 2 ($a2) times, drawing each line
    li $s3, 0                   # i = 0
erase_brick_loop:
    slt $t0, $s3, $s2           # i < size ?
    beq $t0, $0, erase_brick_epi# if not, then done

        # call draw_line
        addi $a0, $s0, 0 # start
        addi $a1, $s1, 0 # colour_address
        li $a2, 4	  # width = 4
        jal draw_line

        addi $s0, $s0, 256      # Go to next row

    addi $s3, $s3, 1            # i = i + 1
    b erase_brick_loop

erase_brick_epi:
    # EPILOGUE
	lw		$ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
	addi	$sp, $sp, 20

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
	addi $s2, $s2, 288	# go to next row (+ 2 lines)	TODO FIGURE OUT WHY 
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
	li $a2, 6	# paddle 6 units wide
	
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
	# 1a. Check if key has been pressed
	lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    	lw $t8, 0($t0)                  # Load first word from keyboard
    	beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    	
    	b detect_collision
    # 1b. Check which key has been pressed
keyboard_input:                     # A key is pressed
    	lw $a0, 4($t0)                  # Load second word from keyboard
    	beq $a0, 0x71, respond_to_Q     # Check if an action key was pressed
    	beq $a0, 0x61, respond_to_A
	beq $a0, 0x64, respond_to_D
	
    	li $v0, 1                       # ask system to print $a0
    	syscall

    	b refresh_ball

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
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
	ble $t0, 3, check_walls
	bge $t0, 60, check_walls
	ble $t0, 8, check_walls
	bge $t0, 23, check_walls
	
	# x_next is between 4 and 59 inclusive and y_next is between 9 and 22 inclusive
	# check for brick collision (3 conditions)
		# check if ball next position is occupied by a brick using get_brick_address
		# condition 1: hit top/bottom of brick -> delete and invert y direction
			# moving vertically results in a collision
			addi $a0, $s0, 0 	# load x
			add $t1, $s1, $s3 	# y_next
			addi $a1, $t1, 0	# load y_next
			jal get_brick_address
			addi $sp, $sp, 8
			lw $a0, 0($sp)		# starting x of brick in units
			lw $a1, 4($sp)		# starting y of brick in units
			addi $t0, $v0, 0	# memory location of brick in BRICK_ARRAY
			lw $v0, 0($v0)		# colour value of the brick
			# if colour at this location isn't 0x000000, erase brick and invert y
			beq $v0, 0, check_walls	# no brick present
			jal get_location_address
			addi $a0, $v0, 0
			jal erase_brick
			b detect_collision_epi
			
		
		# condition 2: hit side of brick -> delete and invert x direction
			# moving horizontally results in a collision
		# condition 3: hit corner of brick -> delete and invert both directions
			# moving in both axes results in a collision
		
	check_walls:	
	add $t0, $s0, $s2 		# check x left out of bounds
	ble $t0, 3, corner_collision 	# branch to corner collision
	bge $t0, 60, corner_collision	# check x right out of bounds
					# branch to corner collision
	add $t0, $s1, $s3		# check y out of bounds
	ble $t0, 3, top_wall_collision # branch to top wall collision
	b detect_collision_epi
	
	top_wall_collision:
	# invert y direction
	addi $t3, $s3, 0		# store value of y direction in temp
	sub $s3, $s3, $t3		# simulate negation by subtracting by itself twice
	sub $s3, $s3, $t3
	la $t0, BALL
	sw $s3, 12($t0)
	b detect_collision_epi
	
	
	wall_collision:
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
	# TODO implement game-over check before this
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
      
	          
	# 2b. Update locations (paddle, ball)
	
	# EPILOGUE
	detect_collision_epi:
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		sw $s3, 12($sp)
		addi $sp, $sp, 16
		b refresh_ball
	
	
respond_to_A:
	li $a0, 1
	jal draw_paddle		# erase paddle
	
	la $t0, PADDLE		# update paddle coord
	lw $t1, 0($t0)
	#TODO case where paddle is at edge of screen
	beq $t1, 4, paddle_max_left
	subi $t1, $t1, 1	# shift paddle 1 unit left	
	sw $t1, 0($t0)

paddle_max_left:
	b refresh_paddle
	
respond_to_D:
	li $a0, 1
	jal draw_paddle		# erase paddle
	
	la $t0, PADDLE		# update paddle coord
	lw $t1, 0($t0)
	
	beq $t1, 54, paddle_max_right
	addi $t1, $t1, 1	# shift paddle 1 unit right	
	sw $t1, 0($t0)
paddle_max_right:
	
	b refresh_paddle
	
	# 3. Draw the screen
refresh_paddle:
	
	li $a0, 0
	jal draw_paddle
	
	b refresh_ball

refresh_ball:
	
	li $a0, 1
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
	
	li $v0, 32
	li $a0, 25
	syscall
	
	b sleep
	
	
	
    	
	# 4. Sleep
sleep:
	li $v0, 32
	li $a0, 25
	syscall
	
    	#5. Go back to 1
    	b game_loop
