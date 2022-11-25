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
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Brick Breaker game.
main:
    # Initialize the game
    jal draw_walls




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


# draw top wall (4 lines from x = 4 -> x = 59) 
	li $a0, 4 # x_value
	li $a1, 0 # y_value
	jal get_location_address # returns loc_addrsss in $v0
	add $t0, $v0, $zero # store starting location for first row
	
	addi $a1, $a1, 256 # add 1 row to y_value
	jal get_location_address # returns loc_addrsss in $v0
	add $t1, $v0, $zero # store starting location for second row
	
	addi $a1, $a1, 256 # add 1 row to y_value
	jal get_location_address # returns loc_addrsss in $v0
	add $t2, $v0, $zero # store starting location for third row
	
	addi $a1, $a1, 256 # add 1 row to y_value 
	jal get_location_address # returns loc_addrsss in $v0
	add $t3, $v0, $zero # store starting location for fourth row
	
	
	add $a0, $t0, $zero # prepare to call draw_line with start position (0, 4)
	la $a1, COLOURS # colour
	addi $a1, $a1, 36
	li $a2, 55 # draw 56 units across (units 4 - 60)
	jal draw_line # draw first row
	# TODO: NEED TO SAVE TEMP VALUES FROM ABOVE IN MEMORY because draw_line overwrites $t0, $t1 ...
	add $a0, $t2, $zero
	jal draw_line # draw second row
	add $a0, $t3, $zero
	jal draw_line # draw third row
	add $a0, $t4, $zero
	jal draw_line # draw fourth row
	


# draw right wall
	
	
draw_walls_loop:





game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    b game_loop
