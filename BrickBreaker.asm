######################################################################
# 			     Brick Breaker                           #
######################################################################
#           Programmed by Jose Chavez, Eric Sparrow, Brad Dragun     #
######################################################################
#	This program requires the Keyboard and Display MMIO          #
#       and the Bitmap Display to be connected to MIPS.              #
#								     #
#       Bitmap Display Settings:                                     #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 512					     #
#	Base Address for Display: 0x10008000 ($gp)		     #
######################################################################

.data

#Game Core information
lives:		.word 3
#Screen 
screenWidth: 	.word 64
screenHeight: 	.word 64

#Colors
backgroundColor:.word	0x000000	 # black
borderColor:    .word	0x008080	 # blue
paddleColor:	.word	0xcc6611	 # orange
brickColor:	.word   0xFF0000	 # red
ballColor:	.word   0x00FF2A	 # green

#Paddle Information
paddleSize:	.word 32
paddleWidth:	.word 32
paddleHeight:	.word 32
paddleX:	.word 26
paddleY:	.word 58
direction:	.word 97 

#Level Information
currentLevel:		.word 1
brickCount1:		.word 30
brickCount2:		.word 36
brickCount3:		.word 70
brickCount4:		.word 92

brickDestroyedCount:    .word 0

#Ball Information
ballX:		.word 30
ballY:		.word 45
ballDelay:	.word 4
ballDelayTemp:	.word 0

#RNG ID
RandID:		.word 1

# direction variable
# 97 - moving left - A
# 100 - moving right - D
# numbers are selected due to ASCII characters

.text

main:
	li $v0, 32
	li $a0, 1
	syscall

######################################################
# Fill Screen to Black, for reset
######################################################
ClearMap:
	beq $ra, $zero, ClearRegisters		#if at program start, $ra will be 0 so we can skip black fill
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location from jal
	
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 	# total number of pixels on screen
	mul $a2, $a2, 4 	# align addresses
	add $a2, $a2, $gp 	# add base of gp
	add $a0, $gp, $zero 	# loop counter
	
FillLoop:
	
	beq $a0, $a2, endFill
	sw $a1, 0($a0) 			# store color
	addiu $a0, $a0, 4 	        # increment counter
	j FillLoop
	
	endFill:	#return to instruction saved from jal
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

######################################################
# Initialize Variables
######################################################
Init:
	beq $ra, $zero, ClearRegisters
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location of return
ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0	
	
	beq $ra, $zero, DrawBorder
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
######################################################
# Draw Border
######################################################

DrawBorder:
	li $t1, 0		# load Y coordinate for the left border
	LeftLoop:
	move $a1, $t1		# move y coordinate into $a1
	li $a0, 0		# load x direction to 0, doesnt change
	jal CoordinateToAddress	# get screen coordinates
	move $a0, $v0		# move screen coordinates into $a0
	lw $a1, borderColor	# move color code into $a1
	jal DrawPixel		# draw the color at the screen location
	add $t1, $t1, 1		# increment y coordinate
	
	bne $t1, 64, LeftLoop	# loop through to draw entire left border
	
	li $t1, 0		# load Y coordinate for right border
	RightLoop:
	move $a1, $t1		# move y coordinate into $a1
	li $a0, 63		# set x coordinate to 63 (right side of screen)
	jal CoordinateToAddress	# convert to screen coordinates
	move $a0, $v0		# move coordinates into $a0
	lw $a1, borderColor	# move color data into $a1
	jal DrawPixel		# draw color at screen coordinates
	add $t1, $t1, 1		# increment y coordinate
	
	bne $t1, 64, RightLoop	# loop through to draw entire right border
	
	li $t1, 0		# load X coordinate for top border
	TopLoop:
	move $a0, $t1		# move x coordinate into $a0
	li $a1, 0		# set y coordinate to zero for top of screen
	jal CoordinateToAddress	# get screen coordinate
	move $a0, $v0		# move screen coordinates to $a0
	lw $a1, borderColor	# store color data to $a1
	jal DrawPixel	        # draw color at screen coordinates
	add $t1, $t1, 1 	# increment X position
	
	bne $t1, 64, TopLoop 	# loop through to draw entire top border

#Draw Level
BeginBricks:
	lw $s7, currentLevel
	li $t1, 0						#load x coordinate for first Brick
	li $t2, 2						#load y coordinate for first Row
	li $t5, 0						#max bricks
	li $t6, 1						#distance between bricks
	beq $s7, 1, jump1
	beq $s7, 2, jump2
	beq $s7, 3, jump3
	beq $s7, 4, jump4
	j GameOver
	
	jump1:
	lw $s6, brickCount1
	jal level1
	j Paddle
	
	jump2:
	lw $s6, brickCount2
	jal level2
	j Paddle
	
	jump3:
	lw $s6, brickCount3
	jal level3
	j Paddle
	
	jump4:
	lw $s6, brickCount4
	jal level4
	j Paddle
######################################################
# Draw Paddle Position
######################################################	
Paddle:
	# Down counter for the init loop and up counter for the paddle
	jal  Ball
	lw   $t6, paddleX       # Store our X in here from now on using init X
	li   $t1, 10
	li   $t2, 0
	li   $t7, 1	        # Starting pause check
PaddleLoop:
	move $a0, $t6		# Value for x
	lw   $a1, paddleY	# Value for y
	add  $a0, $a0, $t2	# increment X coordinate
	jal CoordinateToAddress	# get screen 
	move $a0, $v0		# move screen coordinates to $a0
	lw   $a1, paddleColor	# put color data into $a1
	jal DrawPixel		# draw color at screen position
	
	#Increment the x value but decrement the loop before the branch
	add $t1, $t1, -1
	add $t2, $t2, 1
	bne $t1, 0, PaddleLoop	# loop through to draw entire bottom border
	beq $t7, 1, StartInput  # Extra starting pause to begin
	j InputCheck
	
######################################################
# Check for Direction Change
######################################################
StartInput:
	jal  StartPause
InputCheck:
	jal  Pause
	lw   $t0, ballDelayTemp
	lw   $t1, ballDelay
	addi $t0, $t0, 1
	sw   $t0, ballDelayTemp
	bne  $t0, $t1, BallSkip
	li   $t0, 0
	sw   $t0, ballDelayTemp
	jal  MoveBall
BallSkip:
	
        # get the coordinates for direction change if needed
	li 	$t7, 0
	lw      $t0, 0xFFFF0000	               
    	andi    $t0, $t0,1               	   # isolate LSB, ready bit
    	# Receiver Data Register address
    	lbu     $t7, 0xFFFF0004                    # get key value
    	beq     $t0, $zero,SelectDrawDirection     # is keyboard available?
	
SelectDrawDirection: 
	#check to see which direction to draw
	beq  $t7, 97, DrawLeftLoop
	beq  $t7, 100, DrawRightLoop
	j InputCheck  	                          #jump back to get input if an unsupported key was pressed
	
DrawLeftLoop:
	sb  $zero, 0xFFFF0004                     # store key value back to zero
	
	#check for collision before moving to next
	beq $t6, 1, InputCheck
	
	addi $t1, $zero, 10			  # incrementer for paddleLoop
	addi $t2, $zero 0		          # Value to add to x direction for paddle length
	add  $t6, $t6, -1		          # Move starting x by -1
	
	#Clear that rightmost pixel out
	add  $a0, $zero, $t6		          # Value for x
	add  $a0, $a0, 10		          # increment X coordinate
	lw   $a1, paddleY			  # Value for y
	jal  CoordinateToAddress		  # get screen 
	move $a0, $v0			          # move screen coordinates to $a0
	lw   $a1, backgroundColor		  # put color data into $a1
	jal  DrawPixel			          # draw color at screen position
	
	#Loop back to the paddle draw
	j PaddleLoop

	
DrawRightLoop:	
	sb   $zero, 0xFFFF0004                    # store key value back to zero
	
	#check for collision before moving to next 
	beq  $t6, 53, InputCheck
	
	addi $t1, $zero, 10			  # incrementer for paddleLoop
	addi $t2, $zero 0		          # Value to add to x direction for paddle length
	
	#Clear that leftmost pixel out
	add  $a0, $zero, $t6		          # Value for x
	lw   $a1, paddleY			  # Value for y
	jal  CoordinateToAddress		  # get screen 
	move $a0, $v0			          # move screen coordinates to $a0
	lw   $a1, backgroundColor		  # put color data into $a1
	jal  DrawPixel			          # draw color at screen position
	
	add  $t6, $t6, 1		          # Move starting x by 1
	#Loop back to the paddle draw
	j PaddleLoop
	
##################################################################
#	Ball Spawning
##################################################################

Ball:
	li   $v0, 30	#Get system time
	syscall
	move $a1, $a0
	lw   $a0, RandID
	li   $v0, 40
	syscall
	li   $v0, 42
	li   $a1, 4	#We want an int from 0 to 3
	syscall
	beq  $a0, 3, Ball315
	beq  $a0, 2, Ball225
	beq  $a0, 1, Ball135
Ball45:
	li $s0, 1
	li $s5, -1
	j  BallAfterDirection
Ball135:
	li $s0, -1
	li $s5, -1
	j  BallAfterDirection
Ball225:
	li $s0, -1
	li $s5, 1
	j  BallAfterDirection
Ball315:
	li $s0, 1
	li $s5, 1
BallAfterDirection:
	addi $sp, $sp, -4			#increment stack
	sw   $ra, 0($sp)			#save previous return address
	jal  DrawBall
	
	lw  $ra, 0($sp)
	add $sp, $sp, 4
	jr  $ra
	
##################################################################
#	Ball Drawing and Collision
##################################################################

DrawBall:
	addi $sp, $sp, -4			#increment stack
	sw   $ra, 0($sp)			#save previous return address
	lw   $a0, ballX				#Load in our ball's starting X
	lw   $a1, ballY				#and Y positions.
	jal  CoordinateToAddress
	move $a0, $v0
	lw   $a1, ballColor
	jal  DrawPixel
	
	lw  $ra, 0($sp)
	add $sp, $sp, 4
	jr  $ra
	
UnDrawBall:
	addi $sp, $sp, -4			#increment stack
	sw   $ra, 0($sp)			#save previous return address
	lw   $a0, ballX				#Load in our ball's starting X
	lw   $a1, ballY				#and Y positions.
	jal  CoordinateToAddress
	move $a0, $v0
	lw   $a1, backgroundColor
	jal  DrawPixel
	
	lw  $ra, 0($sp)
	add $sp, $sp, 4
	jr  $ra
	
MoveBall:
	addi $sp, $sp, -4			#increment stack
	sw   $ra, 0($sp)			#save previous return address
	lw   $t0, ballX
	lw   $t1, ballY
	lw   $t3, backgroundColor
	lw   $t4, brickColor

	add  $a0, $t0, $s0
	move $a1, $t1
	jal CoordinateToAddress
	lw  $t2, 0($v0)
	seq  $t5, $t2, $t4
	movn $t8, $a0, $t5
	movn $t9, $a1, $t5
	beq $t2, $t3, SkipX
	
	sub $s0, $zero, $s0
	
SkipX:
	add  $a1, $t1, $s5
	move $a0, $t0
	jal CoordinateToAddress
	lw  $t2, 0($v0)
	seq  $t5, $t2, $t4
	movn $t8, $a0, $t5
	movn $t9, $a1, $t5
	beq  $t2, $t3, SkipY
	
	sub $s5, $zero, $s5
SkipY:

	add   $a0, $t0, $s0
	add   $a1, $t1, $s5
	jal  CoordinateToAddress
	lw   $t2, 0($v0)
	seq  $t5, $t2, $t4
	movn $t8, $a0, $t5
	movn $t9, $a1, $t5
	beq  $t2, $t3, SkipXY

	sub $s0, $zero, $s0
	sub $s5, $zero, $s5
SkipXY:
	beq  $t8, 0, BallEnd
	jal delete
BallEnd:
	jal UnDrawBall
	lw  $t0, ballX
	lw  $t1, ballY
	add $t0, $t0, $s0
	add $t1, $t1, $s5
	sw  $t0, ballX
	sw  $t1, ballY
	jal DrawBall
	lw  $ra, 0($sp)
	add $sp, $sp, 4
	beq $t1, 64, offBottom
		
	jr $ra
	
offBottom:
	jal lifeLost
	
	#Clear the paddle
	li   $t1, 10
	li   $t2, 0
ErasePaddle:
	move $a0, $t6		  # Value for x
	lw   $a1, paddleY	  # Value for y
	add  $a0, $a0, $t2	  # increment X coordinate
	jal  CoordinateToAddress  # get screen 
	move $a0, $v0		  # move screen coordinates to $a0
	lw   $a1, backgroundColor # put color data into $a1
	jal  DrawPixel		  # draw color at screen position
	
	#Increment the x value but decrement the loop before the branch
	add  $t1, $t1, -1
	add  $t2, $t2, 1
	bne  $t1, 0, ErasePaddle	# loop through to draw entire bottom border
	li   $t0, 30
	li   $t1, 45
	sw   $t0, ballX
	sw   $t1, ballY
	j   Paddle
	
	
	
##################################################################
#	Draw Brick
##################################################################

DrawBricks:
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location of row being drawn
	
	addi $t3, $t1, 5			#left edge
	li $t4, 0					#brick count			
	HorizLoop:
	move $a0, $t1				#move x coordinate into a0
	move $a1, $t2				#move y coordinate into a1
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0				#move screen coordinates int a0
	lw $a1, brickColor		#move color code into a1
	jal DrawPixel				#draw color at screen location
	add $t1, $t1, 1			#increment x coordinate
	
	bne $t1, $t3, HorizLoop		#draw brick to be 5 pixels wide
	add $t1, $t1, $t6				#move left edge over empty spaces
	addi $t4, $t4, 1				#increment brick counter
	addi $t3, $t1, 5				#get ending point of next brick
	bne $t4, $t5, HorizLoop		#start drawing next brick
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
level1:
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location of row being drawn

	level1DrawLoop:
	li $t1, 16
	li $t5, 6
	li $t6, 1
	jal DrawBricks
	addi $t2, $t2, 2
	bne $t2, 12, level1DrawLoop
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra

level2:
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location of row being drawn

	li $t0, 31
	li $t5, 1
	li $t6, 1
	li $s1, 12
	
	TopHalf: #draw center diamond
	move $t1, $t0
	jal DrawBricks
	
	slt $s4, $t2, $s1
	addi $t2, $t2, 2
	bne $s4, 1, bottomHalf
	
	addi $t0, $t0, -3
	addi $t5, $t5, 1	
	bne $t2, 24, TopHalf
	
	bottomHalf:
	addi $t0, $t0, 3
	addi $t5, $t5, -1	
	bne $t2, 24, TopHalf
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
level3:
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location of row being drawn

	li $t0, 3
	
	row1_6:
	move $t1, $t0
	li $t5, 7
	li $t6, 3
	jal DrawBricks
	addi $t0,$t0, 1
	addi $t2, $t2, 2
	bne $t0, 8, row1_6
	
	addi $t2, $t2, 2
	row7_12:
	addi $t0,$t0, -1
	move $t1, $t0
	li $t5, 7
	li $t6, 3
	jal DrawBricks
	
	addi $t2, $t2, 2
	bne $t0, 3, row7_12
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
level4:
	addi $sp, $sp, -4			#increment stack
	sw $ra, 0($sp)				#save location of row being drawn

	li $t0, 3
	li $t5, 4
	li $t6, 1
	li $t7, 40
	li $s1, 12
	li $s2, 8
	li $s3, 20
	
	sides:
	move $t1, $t0		#get left edge
	jal DrawBricks		#draw left side
	
	move $t1, $t7		#get right edge
	jal DrawBricks		#draw right side
	
	addi $t2, $t2, 2	#increment height for next row
	beq $t2, 24, sidesDone #sides are done, draw center diamond
	
	slt $s4, $t2, $s2	#if first two rows, decrease Horizontal size
	beq $s4, 1, decHoriz
	
	slt $s4, $t2, $s3 #if last two rows, increase Horizontal size
	beq $s4, 0, incHoriz
	
	j sides
	
	decHoriz:
	addi $t5, $t5, -1	#one less brick
	addi $t7, $t7, 6	#move Horizontal start for left side
	j sides				#draw row
	
	incHoriz: 
	addi $t5, $t5, 1	#one more brick
	addi $t7, $t7, -6	#move Horizontal start for left side
	j sides				#draw row

	sidesDone:#set defaults for center, begin drawing
	li $t0, 30
	li $t5, 1
	li $t2, 2
	
	center: #draw center diamond
	move $t1, $t0
	jal DrawBricks
	
	slt $s4, $t2, $s1
	addi $t2, $t2, 2
	bne $s4, 1, bottomHalfCenter
	
	addi $t0, $t0, -3
	addi $t5, $t5, 1	
	bne $t2, 24, center
	
	bottomHalfCenter:
	addi $t0, $t0, 3
	addi $t5, $t5, -1	
	bne $t2, 24, center
	
	lw $ra, 0($sp)
	add $sp, $sp, 4
	jr $ra
	
##################################################################
#Delete Brick Function
# $t8 -> x coordinate of ball
# $t9 -> y coordinate of ball
##################################################################
delete:
	lw   $t0, brickDestroyedCount
	addi $t0, $t0, 1
	beq  $t0, $s6, levelFinished
	sw   $t0, brickDestroyedCount
	addi $sp, $sp, -4			#increment stack
	sw   $ra, 0($sp)			#save location of jump to delete
	
findLeftEdge:
	lw   $t7, backgroundColor
	move $a0, $t8
	move $a1, $t9
	jal  CoordinateToAddress
	lw   $a1, ($v0)
	beq  $a1, $t7, deleteStart
	addi $t8, $t8, -1
	j    findLeftEdge
	
deleteStart:
	
	addi $t8, $t8, 1
	move $a0, $t8
	move $a1, $t9
	jal  CoordinateToAddress
	move $a0, $v0
	lw   $a1, ($v0)

	beq  $a1, $t7, deleteEnd
	lw   $t7, borderColor
	
	beq  $a1, $t7, deleteEnd
	lw   $t7, backgroundColor
	
	move $a1, $t7
	jal  DrawPixel
	j    deleteStart
	
deleteEnd:
	li  $t8, 0
	li  $t9, 0
	lw  $ra, 0($sp)
	add $sp, $sp, 4
	jr  $ra
	
levelFinished:
	#clear count of bricks destroyed
	move $t0, $zero
	sw   $t0, brickDestroyedCount
	
	#increment current level
	lw $t0, currentLevel
	addi $t0, $t0, 1
	sw   $t0, currentLevel
	
	#return ball to start position
	addi $t0, $zero, 35
	sw $t0, ballX
	addi $t0, $zero, 45
	sw $t0, ballY
	
	#clear map, registers, and start new level
	jal ClearMap
	jal Init
	j DrawBorder

##################################################################
# Life Lost
#
##################################################################
lifeLost:
	lw $t9, lives
	beq $t9, 0, GameOver
	
	addi $t9, $t9, -1
	sw $t9, lives
	jr $ra

##################################################################
#CoordinatesToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
##################################################################
# returns $v0 -> the address of the coordinates for bitmap display
##################################################################
CoordinateToAddress:
	lw $v0, screenWidth 	# Store screen width into $v0
	mul $v0, $v0, $a1	# multiply by y position
	add $v0, $v0, $a0	# add the x position
	mul $v0, $v0, 4		# multiply by 4
	add $v0, $v0, $gp	# add global pointerfrom bitmap display
	jr $ra			# return $v0
	
##################################################################
#Draw Function
# $a0 -> Address position to draw at
# $a1 -> Color the pixel should be drawn
##################################################################
# no return value
##################################################################
DrawPixel:
	sw $a1, ($a0) 		# fill the coordinate with specified color
	jr $ra			# return
	
##################################################################
# Pause Function
# $a0 - amount to pause
##################################################################
# no return values
##################################################################
Pause:
	li $v0, 32 #syscall value for sleep
	li $a0, 25
	syscall
	jr $ra
StartPause:
	li $v0, 32 #syscall value for sleep
	li $a0, 1000
	syscall
	jr $ra
	
##################################################################
# Game Over 
#
##################################################################
GameOver:
	#Row 1
	li $t1, 23
	li $t2, 32
	g_1:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 27 , g_1
	
	addi $t1, $t1, 2
	
	a_1:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 31 , a_1 
	
	addi $t1, $t1, 2
	
	m_1:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 4
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	e_1:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 42 , e_1
	
	#row 2
	addi $t2, $t2, 1
	addi $t1, $zero, 23
	
	g_2:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 5
	
	a_2:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	m_2:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 35, m_2
	
	addi $t1, $t1, 1
	splitM:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 38, splitM
	
	addi $t1, $t1, 1
	
	e_2:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	#row 3
	addi $t2, $t2, 1
	addi $t1, $zero, 23
	
	g_3:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	splitG:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 27, splitG
	
	addi $t1, $t1, 1
	
	a_3:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 32, a_3
	
	addi $t1, $t1, 1
	
	m_3:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	bne $t1, 39, m_3
	
	e_3:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 42, e_3
	
	#row4
	addi $t2, $t2, 1
	addi $t1, $zero, 23
	
	g_4:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	a_4:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	m_4:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 4
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel 
	
	addi $t1, $t1, 2
	
	e_4:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	#row5
	addi $t2, $t2, 1
	addi $t1, $zero, 23
	g_5:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 27, g_5
	
	addi $t1, $t1, 1
	
	a_5:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	m_5:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 4
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	e_5:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 42, e_5
	
	#row 7
	addi $t2, $t2, 2
	addi $t1, $zero, 24
	o_7:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 28, o_7 
	
	addi $t1, $t1, 1
	
	v_7:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	e_7:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 37, e_7
	
	addi $t1, $t1, 1
	
	r_7:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 41, r_7
	
	#row 8
	addi $t2, $t2, 1
	addi $t1, $zero, 24
	o_8:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	v_8:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	e_8:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 4
	
	r_8:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	#row 9
	addi $t2, $t2, 1
	addi $t1, $zero, 24
	o_9:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	v_9:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	e_9:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 37 , e_9 
	addi $t1, $t1, 1
	
	r_9:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 41 , r_9
	
	#row 10
	addi $t2, $t2, 1
	addi $t1, $zero, 24
	o_10:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	v_10:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 3
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	e_10:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 4
	
	
	r_10:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 40, r_10
	
	#row 11
	addi $t2, $t2, 1
	addi $t1, $zero, 24
	o_11:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 28 , o_11
	addi $t1, $t1, 2
	
	v_11:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 32, v_11
	
	addi $t1, $t1, 2
	
	e_11:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 1
	bne $t1, 37, e_11 
	addi $t1, $t1, 1
	
	r_11:
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
	addi $t1, $t1, 2
	
	move $a0, $t1
	move $a1, $t2
	jal CoordinateToAddress
	move $a0, $v0
	lw $a1, brickColor
	jal DrawPixel
	
Exit:
    li $v0, 10
    syscall
