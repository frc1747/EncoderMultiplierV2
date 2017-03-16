/*
 * EncoderMultiplierV2.asm
 *
 *  Created: 2/25/2017 10:02:31 PM
 *   Author: Tiger
 */ 

// --------------------------------------------------
// Init section

// Register definitions
.DEF temp = r18
.DEF in_mask = r2
.DEF out_mask = r3
.DEF inv_out_mask = r6
.DEF old_pinb = r17
.DEF cur_pinb = r16
.DEF WL = r24
.DEF WH = r25
.DEF scale_low = r22
.DEF scale_high = r23
.DEF max_low = r0
.DEF max_high = r1
.DEF out_buf = r19
.DEF out_buf2 = r20
.DEF zero_low = r4
.DEF zero_high = r5

// Create the masks
LDI temp, 0x02
MOV in_mask, temp
LDI temp, 0x18
MOV out_mask, temp
MOV inv_out_mask, out_mask
COM inv_out_mask

// Set the IO mode and pullups
OUT DDRB, out_mask
OUT PORTB, in_mask

// Period scaler
LDI scale_low, 100
LDI scale_high, 0

// Set the max period
LDI temp, 0x1B
MOV max_low, temp
LDI temp, 0x41
MOV max_high, temp

// XL, XH -> input counter
// YL, YH -> output counter
// WL, WH -> saved period
MOV WL, max_low
MOV WH, max_high

// Create the zero registers
CLR zero_low
CLR zero_high

// Init the out buffer
LDI out_buf, 0x33
LDI out_buf2, 0x10

// Init input registers
IN old_pinb, PINB

// --------------------------------------------------
// Main program loop

loop:
	NOP
	// --------------------------------------------------
	// Input section

	// Increment the input counter register
	ADIW XH:XL, 1

	// Read in the current pins
	IN cur_pinb, PINB
	// Bit is set on a rising edge
	COM old_pinb
	AND old_pinb, cur_pinb
	// Extract the actual pin
	AND old_pinb, in_mask
	
	// Test to see if there was a change
	TST old_pinb
	BRNE rising
		NOP
	RJMP end_rising
	rising:
		// Save the period
		MOVW WH:WL, XH:XL
		// Reset the input counter
		MOVW XH:XL, zero_high:zero_low
	end_rising:

	// Save the old pin values
	MOV old_pinb, cur_pinb
	
	// --------------------------------------------------
	// Limit period section
	
	// Lower limit
	CP WL, scale_low
	CPC WH, scale_high
	BRGE not_too_small
		MOVW WH:WL, scale_high:scale_low
	not_too_small:
	
	// Upper limit
	CP max_low, XL
	CPC max_high, XH
	BRLT too_large
		NOP
	RJMP end_too_large
	too_large:
		// Cap the input counter
		MOVW XH:XL, max_high:max_low
		// Set the saved period
		MOVW WH:WL, max_high:max_low
	end_too_large:

	// --------------------------------------------------
	// Output section

	// Decrement the output counter register
	SUB YL, scale_low
	SBC YH, scale_high

	// Check if need to invert the output
	BRLT toggle
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
	RJMP end_toggle
	toggle:
		// Add the period back to this timer
		// (to reduce long term error)
		ADD YL, WL
		ADC YH, WH

		// Move to the next output state
		LSL out_buf
		BRCC no_carryover
			INC out_buf
		no_carryover:

		// Read in the old state and desired state
		IN temp, PORTB
		MOV out_buf2, out_buf

		// Apply the masks
		AND temp, inv_out_mask
		AND out_buf2, out_mask

		// Combine the states
		OR temp, out_buf2
		OUT PORTB, temp
	end_toggle:

	rjmp loop
