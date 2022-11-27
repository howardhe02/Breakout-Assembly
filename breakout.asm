################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
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
	.word 0xd23be7 #purple (28)
	.word 0x000000	#black (32)
	.word 0xfffdd0	#lean (36)
	
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
	.space 4	#reserve space for direction of ball
	.space 4	#reserve space for speed of ball
	.space 4	#reserve space for colour of ball

<<<<<<< HEAD
BRICK_ARRAY
	.word
=======
BRICK_ARRAY:
	.word 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f, 0xe6261f
	.word 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532, 0xeb7532
	.word 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038, 0xf7d038,0xf7d038
	.word 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048, 0xa3e048
	.word 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a, 0x49da9a
	.word 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6, 0x34bbe6
	.word 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db, 0x4355db
>>>>>>> a0880d73f15b60b42e4d67010fe1aeaa19cc0267
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    jal draw_walls
    jal draw_bricks




# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 64, inclusive
#       - y is between 0 and 64, inclusive
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
# draw left wall 



	


# draw right wall
	
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
<<<<<<< HEAD
	
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
	

=======
	
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
>>>>>>> a0880d73f15b60b42e4d67010fe1aeaa19cc0267

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
	li $s1, 393	# 98 bricks x 4 bytes to get to next brick = 392
	li $s3, 0
draw_brick_loop:
	slt $t1, $s0, $s1	# i < 64
	beq $t1, $0, end_brick_loop
	
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
	beq $t4, $0, else
	j draw_brick_loop
else:
	addi $s2, $s2, 288	# go to next row (+ 2 lines)	TODO FIGURE OUT WHY 
	j draw_brick_loop
		
end_brick_loop:
	#EPILOGUE
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw, $s1, 8($sp)
	lw, $s2, 12($sp)
	addi $sp, $sp, 16
	
	jr $ra
	

draw_bricks_epi:

game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop
