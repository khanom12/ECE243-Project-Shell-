#.include "nios_macros.s"

.section .text

.equ PERIOD, 1666668				    # 1/60 second period

.equ TIMER_STATUS, 0					# TIMER registers
.equ TIMER_CONTROL, 4
.equ PERIOD_L, 8
.equ PERIOD_H, 12

######################################################################################################################################	
################################################################# Main Program  ######################################################
######################################################################################################################################	

.equ TIMER_ADDRESS, 0xff202000			# TIMER base address

.global main

main:
	addi sp, sp, -4
	stw ra, 0(sp)

	# Move TIMER base to r8
	movia r8, TIMER_ADDRESS
	
	# Store period in period register
	movui r9, %lo(PERIOD)
	stwio r9, PERIOD_L(r8)
	movui r9, %hi(PERIOD)
	stwio r9, PERIOD_H(r8)
	
	# Clear timeout bit
	stwio r0, TIMER_STATUS(r8)
	
	# Start timer, continue, enable interrupt
	movi r9, 0b111
	stwio r9, TIMER_CONTROL(r8)

	# Enable IRQ line 0 for timer, IRQ line 1 for push keys, IRQ line 6 for audio codec, IRQ line 7 for PS2
	movi r9, 0b00000001
	wrctl ctl3, r9
	
	# Enable external interrupts
	movi r9, 1
	wrctl ctl0, r9

LOOP:
	br LOOP
	
	ldw ra, 0(sp)
	addi sp, sp, 4
	
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

CHECK_TIMER:
	mov r16, et
	
	# Isolate bit 0 for timer interrupt check
	andi r16, r16, 1
	
	# Check push if interrupt wasn't from timer
	beq r16, r0, EXIT_TIMER
	
TIMER_INTERRUPT:
	# Clear timeout bit
	movia et, TIMER
	stwio r0, TIMER_STATUS(et)
	
	br EXIT_TIMER

EXIT_TIMER:
	br EPILOGUE

EPILOGUE:
	ldw r16, 0(sp)
	ldw r17, 4(sp)
	ldw r18, 8(sp)
	ldw r19, 12(sp)
	ldw r20, 16(sp)
	ldw r21, 20(sp)
	ldw r22, 24(sp)
	ldw r23, 28(sp)
	
	addi sp, sp, 32

	addi ea, ea, -4
	eret
	
