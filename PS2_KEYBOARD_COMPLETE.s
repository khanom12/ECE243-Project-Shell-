.include "nios_macros.s"

.section .data

PS2_BUFFER:						# Place in memory in which keys pressed are stored (to be used by VGA console)
	.skip 4800

PS2_BUFFER_QUANTITY:			# Number of keys stored in PS2_BUFFER
	.skip 4

PS2_BUFFER_POSITION:			# Position of current key pressed in PS2_BUFFER 
	.skip 4

.section .text

################################################################# Encoding for keys (VGA ascii) ######################################	
# These hex values for the keys are recognized by the VGA and thus interpreted into pixels for output on screen
.equ UP, 0x18						
.equ DOWN, 0x19
.equ LEFT, 0x1a
.equ RIGHT, 0x1b

.equ SPACE, 0x20
.equ BKSP, 0x08
.equ EOF, 0x04

.equ ALIAS_A, 0x41
.equ ALIAS_B, 0x42
.equ ALIAS_C, 0x43
.equ ALIAS_D, 0x44
.equ ALIAS_E, 0x45
.equ ALIAS_F, 0x46
.equ ALIAS_G, 0x47
.equ ALIAS_H, 0x48
.equ ALIAS_I, 0x49
.equ ALIAS_J, 0x4a
.equ ALIAS_K, 0x4b
.equ ALIAS_L, 0x4c
.equ ALIAS_M, 0x4d
.equ ALIAS_N, 0x4e
.equ ALIAS_O, 0x4f
.equ ALIAS_P, 0x50
.equ ALIAS_Q, 0x51
.equ ALIAS_R, 0x52
.equ ALIAS_S, 0x53
.equ ALIAS_T, 0x54
.equ ALIAS_U, 0x55
.equ ALIAS_V, 0x56
.equ ALIAS_W, 0x57
.equ ALIAS_X, 0x58
.equ ALIAS_Y, 0x59
.equ ALIAS_Z, 0x5a

.equ ALIAS_0, 0x30
.equ ALIAS_1, 0x31
.equ ALIAS_2, 0x32
.equ ALIAS_3, 0x33
.equ ALIAS_4, 0x34
.equ ALIAS_5, 0x35
.equ ALIAS_6, 0x36
.equ ALIAS_7, 0x37
.equ ALIAS_8, 0x38
.equ ALIAS_9, 0x39

################################################################# Encoding for keys (VGA ascii) #######################################

################################################################# PS2 Code Set 3  #####################################################
# When a key is pressed, the ps2 sends these values to be recognized for key press
.equ PS2_UP, 0x63				
.equ PS2_DOWN, 0x60
.equ PS2_LEFT, 0x61
.equ PS2_RIGHT, 0x6a

.equ PS2_SPACE, 0x29
.equ PS2_BKSP, 0x66

.equ PS2_A, 0x1c
.equ PS2_B, 0x32
.equ PS2_C, 0x21
.equ PS2_D, 0x23
.equ PS2_E, 0x24
.equ PS2_F, 0x2b
.equ PS2_G, 0x34
.equ PS2_H, 0x33
.equ PS2_I, 0x43
.equ PS2_J, 0x3b
.equ PS2_K, 0x42
.equ PS2_L, 0x4b
.equ PS2_M, 0x3a
.equ PS2_N, 0x31
.equ PS2_O, 0x44
.equ PS2_P, 0x4d
.equ PS2_Q, 0x15
.equ PS2_R, 0x2d
.equ PS2_S, 0x1b
.equ PS2_T, 0x2c
.equ PS2_U, 0x3c
.equ PS2_V, 0x2a
.equ PS2_W, 0x1d
.equ PS2_X, 0x22
.equ PS2_Y, 0x35
.equ PS2_Z, 0x1a

.equ PS2_0, 0x45
.equ PS2_1, 0x16
.equ PS2_2, 0x1e
.equ PS2_3, 0x26
.equ PS2_4, 0x25
.equ PS2_5, 0x2e
.equ PS2_6, 0x36
.equ PS2_7, 0x3d
.equ PS2_8, 0x3e
.equ PS2_9, 0x46

################################################################# PS2 Code Set 3 #####################################################

######################################################################################################################################	
################################################################# Main Program  ######################################################
######################################################################################################################################	

.equ PS2_ADDRESS, 0xFF200100		

.global main

main:
	addi sp, sp, -4
	stw ra, 0(sp)
	
INITIALIZE_PS2:
	# moving KEYBOARD base to r8
	movia r8, PS2_ADDRESS
	 
	# resetting PS2
	movi r9, 0xFF
	stbio r9, 0(r8)
	call POLL_ACKNOWLEDGE
	call POLL_RESET
	
	# enabling code set 3
	movi r9, 0xF0
	stbio r9, 0(r8)
	call POLL_ACKNOWLEDGE
	movi r9, 0x03
	stbio r9, 0(r8)
	call POLL_ACKNOWLEDGE	
	
	# disabling all break (code set 3)
	movi r9, 0xF9
	stbio r9, 0(r8)
	call POLL_ACKNOWLEDGE
	
INITIALIZE_PS2_INTERRUPT:	
	# enabling read interrupts for ps2
	movi r9, 1
	stwio r9, 4(r8)
	
	# enable IRQ line 7 for PS2
	movi r9, 0b10000000
	wrctl ctl3, r9
	
	# enable external interrupts for CPU
	movi r9, 1
	wrctl ctl0, r9

INITIALIZE_PS2_DATA:
	# Initialize PS2_BUFFER to EOF
	movia r9, PS2_BUFFER
	movi r10, EOF
	sth r10, 0(r9)

	#Initialize ps2 buffer quantity to 0
	movia r9, PS2_BUFFER_QUANTITY
	stw r0, 0(r9)

	#Initialize PS2_BUFFER_POSITION to &( PS2_BUFFER ) + PS2_BUFFER_QUANTITY
	movia r9, PS2_BUFFER_POSITION
	ldw r9, 0(r9)

	movia r10, PS2_BUFFER_QUANTITY
	ldw r10, 0(r10)

	add r9, r9, r10
	movia r10, PS2_BUFFER
	stw r9, 0(r10)
	
LOOP:
	br LOOP
	
	ldw ra, 0(sp)
	addi sp, sp, 4
	
	ret

PS2_POLLS:
	
POLL_ACKNOWLEDGE:
	movia r2, PS2_ADDRESS
	ldbio r2, 0(r2)
	andi r2, r2, 0xff
	
	movi r3, 0xfa
	bne r2, r3, POLL_ACKNOWLEDGE
	
	ret
	
POLL_RESET:
	movia r2, PS2_ADDRESS
	ldbio r2, 0(r2)
	andi r2, r2, 0xff
	
	movi r3, 0xaa
	bne r2, r3, POLL_RESET
	
	ret

#######################################################################################################################################	
############################################################################ Interrupt Handler ########################################
#######################################################################################################################################	
.section .exceptions, "ax"
PROLOGUE:
	addi sp, sp, -36
	
	stw r16, 0(sp)    
	stw r17, 4(sp)
	stw r18, 8(sp)
	stw r19, 12(sp)
	stw r20, 16(sp)
	stw r21, 20(sp)
	stw r22, 24(sp)
	stw r23, 28(sp)
	stw ra, 32(sp)

INTERRUPT_HANDLER:
	# Obtain IRQ line
	rdctl et, ctl4
	
######################################################################### PS2 Interrupt ################################################
CHECK_PS2:
	mov r16, et
	
	# Isolate bit 7 for PS2
	andi r16, r16, 0b10000000
	
	# Check if Interrupt is from PS2
	beq r16, r0, EXIT_PS2

PS2_INTERRUPT:	
	# reading ps2 data (Acknowledge interrupt)
	movia et, PS2_ADDRESS
	ldbio et, 0(et)

	# Condition check for which key is pressed
	movi r16, PS2_UP
	beq et, r16, SET_PS2_UP
	movi r16, PS2_DOWN
	beq et, r16, SET_PS2_DOWN
	movi r16, PS2_LEFT
	beq et, r16, SET_PS2_LEFT
	movi r16, PS2_RIGHT
	beq et, r16, SET_PS2_RIGHT
	
	movi r16, PS2_SPACE
	beq et, r16, SET_PS2_SPACE
	movi r16, PS2_BKSP
	beq et, r16, SET_PS2_BKSP
	
	movi r16, PS2_A
	beq et, r16, SET_PS2_A
	movi r16, PS2_B
	beq et, r16, SET_PS2_B
	movi r16, PS2_C
	beq et, r16, SET_PS2_C
	movi r16, PS2_D
	beq et, r16, SET_PS2_D
	movi r16, PS2_E
	beq et, r16, SET_PS2_E
	movi r16, PS2_F
	beq et, r16, SET_PS2_F
	movi r16, PS2_G
	beq et, r16, SET_PS2_G
	movi r16, PS2_H
	beq et, r16, SET_PS2_H
	movi r16, PS2_I
	beq et, r16, SET_PS2_I
	movi r16, PS2_J
	beq et, r16, SET_PS2_J
	movi r16, PS2_K
	beq et, r16, SET_PS2_K
	movi r16, PS2_L
	beq et, r16, SET_PS2_L
	movi r16, PS2_M
	beq et, r16, SET_PS2_M
	movi r16, PS2_N
	beq et, r16, SET_PS2_N
	movi r16, PS2_O
	beq et, r16, SET_PS2_O
	movi r16, PS2_P
	beq et, r16, SET_PS2_P
	movi r16, PS2_Q
	beq et, r16, SET_PS2_Q
	movi r16, PS2_R
	beq et, r16, SET_PS2_R
	movi r16, PS2_S
	beq et, r16, SET_PS2_S
	movi r16, PS2_T
	beq et, r16, SET_PS2_T
	movi r16, PS2_U
	beq et, r16, SET_PS2_U
	movi r16, PS2_V
	beq et, r16, SET_PS2_V
	movi r16, PS2_W
	beq et, r16, SET_PS2_W
	movi r16, PS2_X
	beq et, r16, SET_PS2_X
	movi r16, PS2_Y
	beq et, r16, SET_PS2_Y
	movi r16, PS2_Z
	beq et, r16, SET_PS2_Z
	
	movi r16, PS2_0
	beq et, r16, SET_PS2_0
	movi r16, PS2_1
	beq et, r16, SET_PS2_1
	movi r16, PS2_2
	beq et, r16, SET_PS2_2
	movi r16, PS2_3
	beq et, r16, SET_PS2_3
	movi r16, PS2_4
	beq et, r16, SET_PS2_4
	movi r16, PS2_5
	beq et, r16, SET_PS2_5
	movi r16, PS2_6
	beq et, r16, SET_PS2_6
	movi r16, PS2_7
	beq et, r16, SET_PS2_7
	movi r16, PS2_8
	beq et, r16, SET_PS2_8
	movi r16, PS2_9
	beq et, r16, SET_PS2_9
	
	br EXIT_PS2

# Store keys pressed into memory in order of key pressed followed by and EOF key which is to be interpreted by VGA
SET_PS2_UP:
	movi r16, UP
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_DOWN:
	movi r16, DOWN
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2
	
SET_PS2_LEFT:
	movi r16, LEFT
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_RIGHT:
	movi r16, RIGHT
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_SPACE:
	movi r16, SPACE
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2
	
SET_PS2_BKSP:
	movi r16, BKSP
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_A:
	movi r16, ALIAS_A
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_B:
	movi r16, ALIAS_B
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_C:
	movi r16, ALIAS_C
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_D:
	movi r16, ALIAS_D
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_E:
	movi r16, ALIAS_E
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_F:
	movi r16, ALIAS_F
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2
	
SET_PS2_G:
	movi r16, ALIAS_G
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_H:
	movi r16, ALIAS_H
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_I:
	movi r16, ALIAS_I
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_J:
	movi r16, ALIAS_J
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_K:
	movi r16, ALIAS_K
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_L:
	movi r16, ALIAS_L
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br EPILOGUE

SET_PS2_M:
	movi r16, ALIAS_M
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_N:
	movi r16, ALIAS_N
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_O:
	movi r16, ALIAS_O
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_P:
	movi r16, ALIAS_P
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_Q:
	movi r16, ALIAS_Q
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_R:
	movi r16, ALIAS_R
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_S:
	movi r16, ALIAS_S
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_T:
	movi r16, ALIAS_T
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_U:
	movi r16, ALIAS_U
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_V:
	movi r16, ALIAS_V
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2
		
SET_PS2_W:
	movi r16, ALIAS_W
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_X:
	movi r16, ALIAS_X
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_Y:
	movi r16, ALIAS_Y
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_Z:
	movi r16, ALIAS_Z
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_0:
	movi r16, ALIAS_0
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_1:
	movi r16, ALIAS_1
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_2:
	movi r16, ALIAS_2
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_3:
	movi r16, ALIAS_3
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_4:
	movi r16, ALIAS_4
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_5:
	movi r16, ALIAS_5
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_6:
	movi r16, ALIAS_6
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_7:
	movi r16, ALIAS_7
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_8:
	movi r16, ALIAS_8
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2

SET_PS2_9:
	movi r16, ALIAS_9
	movia et, PS2_BUFFER_POSITION
	ldw r17, 0(et)
	stb r16, 0(r17)

	addi r17, r17, 1
	movi r16, EOF
	stb r16, 0(r17)

	br UPDATE_PS2


UPDATE_PS2:
	# Add 1 to PS2_BUFFER_QUANTITY (add 1 to counter)
	movia et, PS2_BUFFER_QUANTITY
	ldw r16, 0(et)

	addi r16, r16, 1
	stw r16, 0(et)

	movia et, PS2_BUFFER
	ldb r17, 0(et)

	# Update PS2_BUFFER_POSITION
	add r16, r16, r17

	movia et, PS2_BUFFER_POSITION
	stw r16, 0(et)

EXIT_PS2:
	br EPILOGUE

######################################################################### PS2 Interrupt #################################################
	
EPILOGUE:
	ldw r16, 0(sp)     
	ldw r17, 4(sp)
	ldw r18, 8(sp)
	ldw r19, 12(sp)
	ldw r20, 16(sp)
	ldw r21, 20(sp)
	ldw r22, 24(sp)
	ldw r23, 28(sp)
	ldw ra, 32(sp)
	
	addi sp, sp, 36	   

	addi ea, ea, -4
	eret	
