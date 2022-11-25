################ CSC258H1F Fall 2022 Assembly Final Project ##################
# This file contains our implementation of Breakout.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number
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
	.word 0xe6261f	#red
	.word 0xeb7532	#orange
	.word 0xf7d038	#yellow
	.word 0xa3e048	#green
	.word 0x49da9a	#jade
	.word 0x34bbe6	#sky
	.word 0x4355db	#blue
	.word 0x000000	#black
	.word fffdd0	#lean
	
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

# get_location_address(x, y) -> address
#   Return the address of the unit on the display at location (x,y)
#
#   Preconditions:
#       - x is between 0 and 31, inclusive
#       - y is between 0 and 31, inclusive
get_location_address:
	# BODY
	sll $a0, $a0, 2 # x_bytes = x * 4
	sll $a1, $a1, 7 # y_bytes = y * 128
	
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
