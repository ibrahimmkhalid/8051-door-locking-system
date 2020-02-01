;;;;;;;;
;Assumptions
;Password length 4
;
;
;
;Ram location usages
;;;;;;;;
;R0		used as general/upper memory pointer
;R1-3 	used by keypad reading function
;31H 	used by keypad reading function
;R4		String counter, length
;R5		Password length = 4
;30H	Delay multiplier
;32H 	number of people in building
;33H	used by door open/close function
;34H	used by countdown timer
;35H	used by countdown timer
;40H	keypad return value 0-9
;41Hb 	correct input bool bit 
;42Hb	EX0 interrupt flag
;43Hb	EX1 interrupt flag
;44Hb	show countdown timer
;50-57	Passcode
;70-7F	Random
;;;;;;;;;;;
;Password compare range
;50H  51H  52H  53H
;54H  55H  56H  57H
;
;
;LCD Ram locations to Screen location
;	0123456789ABCDEF
;80 Code:xxxx       
;C0 Err 5 tries left
;90 attempts left:x
;D0 People:xx       
;;;;;;;;
org 0000H
	jmp init
org 0003H
	jmp EX0_ISR
org 0013H
	jmp EX1_ISR
org 0030H
init:
mov R0, #54H
mov R4, #0H
mov dptr, #passcode
set_password_check_region_loop:
	mov A, R4
	movc A, @A+DPTR
	mov @R0, A
	inc R0
	inc R4
cjne A, #0, set_password_check_region_loop

mov P0, #000H
mov P1, #000H
mov P2, #000H

setb EA
setb EX1
setb IT1


mov A, #08H			
call write_command
mov A, #38H
call write_command
mov R5, #4
mov 32H, #9


jmp main

main:
	clr EX0
	mov TMOD, #00010001B
	call closedoor
	mov A, #0CH			
	call write_command
	call main_display
	mov A, 32H
	check_max_capacity_again:
	cjne A, #10, continue_main
	call display_max_capacity
	jmp check_max_capacity_again
	continue_main:
	call get_verified_input
	jnb 41H, incorrect_password
		setb EX0
		setb IT0
		setb 44H
		call opendoor5s
		clr 44H
		clr EX0
	jmp back_to_start
	incorrect_password:
		clr EX1
		call allowRetries3
		setb EX1
	back_to_start:
	mov A, #08H			
	call write_command
jmp main

display_max_capacity:
	mov dptr, #str_main_display_maxcap
	mov R4, #0H
	mov A, #01H
	call write_command


	mov A, #080H				;line 1
	call write_command

	str_maxcap_1:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_maxcap_1_a
		jmp str_maxcap_1_end
	str_maxcap_1_a:
		call write_data
		jmp str_maxcap_1
	str_maxcap_1_end:

	mov A, #0C0H				;line 2
	call write_command

	str_maxcap_2:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_maxcap_2_a
		jmp str_maxcap_2_end
	str_maxcap_2_a:
		call write_data
		jmp str_maxcap_2
	str_maxcap_2_end:

	mov A, #090H				;line 3
	call write_command

	str_maxcap_3:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_maxcap_3_a
		jmp str_maxcap_3_end
	str_maxcap_3_a:
		call write_data
		jmp str_maxcap_3
	str_maxcap_3_end:

	mov A, #0D0H				;line 4
	call write_command

	str_maxcap_4:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_maxcap_4_a
		jmp str_maxcap_4_end
	str_maxcap_4_a:
		call write_data
		jmp str_maxcap_4
	str_maxcap_4_end:

ret

clear_passcode:
	mov A, #85H
	call write_command
	mov 71H, R5
	clear_passcode_loop:
		mov A, #20H
		call write_data
	djnz 71H, clear_passcode_loop
ret

main_display:
	mov dptr, #str_main_display
	mov R4, #0H
	mov A, #01H
	call write_command
	mov A, #080H				;line 1
	call write_command


	str_main_display_1:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_main_display_1_a
		jmp str_main_display_1_end
	str_main_display_1_a:
		call write_data
		jmp str_main_display_1
	str_main_display_1_end:

	mov A, #0D0H				;line 4
	call write_command

	str_main_display_2:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_main_display_2_a
		jmp str_main_display_2_end
	str_main_display_2_a:
		call write_data
		jmp str_main_display_2
	str_main_display_2_end:

	call display_num_in_room

	mov A, #85H
	call write_command
ret

display_num_in_room:
	mov A, #0D7H
	call write_command
	mov A, 32H
	cjne A, #0FFH, non_negative_check
		mov A, #0
		mov 32H, #0
	non_negative_check:
	cjne A, #10, single_digit_display
	double_digit_display:
		mov A, #31H
		call write_data
		mov A, #30H
		call write_data
	jmp end_digit_display
	single_digit_display:
		add A, #30H
		call write_data
	end_digit_display:
ret

write_command:
	clr P2.7
	clr P2.6
	mov P0, A
	setb P2.5
	clr P2.5
	setb P2.6
	clr P2.7
	setb P0.7
	writing_command:
		clr P2.5
		setb P2.5
		jb P0.7, writing_command
	;mov 30H, #1
	;call delay_50ms
ret

write_data:
	setb P2.7
	clr P2.6
	mov P0, A
	setb P2.5
	clr P2.5
	setb P2.6
	clr P2.7
	setb P0.7
	writing_data:
		clr P2.5
		setb P2.5
		jb P0.7, writing_data
	;mov 30H, #1
	;call delay_50ms
ret

get_verified_input:
	mov A, #85H
	call write_command
	mov 71H, R5
	mov R0, #50H
	get_verified_input_loop:
		call keypadRead
		mov A, 40H
		call write_data
		mov @R0, 40H
		inc  R0
	djnz 71H, get_verified_input_loop
	mov A, 50H
	cjne A, 54H, wrong_passcode
	mov A, 51H
	cjne A, 55H, wrong_passcode
	mov A, 52H
	cjne A, 56H, wrong_passcode
	mov A, 53H
	cjne A, 57H, wrong_passcode
	correct_passcode:
		setb 41H
	jmp end_get_verified_input
	wrong_passcode:
		clr 41H
end_get_verified_input:
	mov 30H, #10
	call delay_50ms
	call clear_passcode
ret

countdown_timer:
	mov A, #0C0H				;line 2
	call write_command
	mov dptr, #str_main_display_passright
	mov R4, #0
	str_countdown_timer_1:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_countdown_timer_1_a
		jmp str_countdown_timer_1_end
	str_countdown_timer_1_a:
		call write_data
		jmp str_countdown_timer_1
	str_countdown_timer_1_end:

	mov A, #090H				;line 3
	call write_command

	str_countdown_timer_2:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_countdown_timer_2_a
		jmp str_countdown_timer_2_end
	str_countdown_timer_2_a:
		call write_data
		jmp str_countdown_timer_2
	str_countdown_timer_2_end:
	mov A, #35H
	call write_data
ret

update_countdown_retries:
	mov A, #0C0H				;line 2
	call write_command
	mov dptr, #str_main_display_passwrong
	mov R4, #0
	str_countdown_retries_1:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_countdown_retries_1_a
		jmp str_countdown_retries_1_end
	str_countdown_retries_1_a:
		call write_data
		jmp str_countdown_retries_1
	str_countdown_retries_1_end:

	mov A, #090H				;line 3
	call write_command

	str_countdown_retries_2:
		mov A, R4
		inc R4
		movc A, @A+dptr
	cjne A,#0,str_countdown_retries_2_a
		jmp str_countdown_retries_2_end
	str_countdown_retries_2_a:
		call write_data
		jmp str_countdown_retries_2
	str_countdown_retries_2_end:
	mov A, 36H
	add A, #30H
	call write_data
ret

update_countdown_timer:
	mov A, #9DH
	call write_command
	mov A, 35H
	call write_data
ret

openDoor5s:
	clr 42H
	mov 33H, #100
	mov 34H, #0
	mov 35H, #35H
	jnb 44H, openDoor_loop
	call countdown_timer
	openDoor_loop:
		mov tl1, #0FDH 
		mov th1, #04BH
		clr tf1
		setb tr1
		openDoor_:
			jnb 44H, not_dec_timer
			mov A, 34H
			cjne A, #20, not_dec_timer
				mov 34H, #0
				dec 35H
				call update_countdown_timer
			not_dec_timer:
			jb 42H, interrupt_closedoor
			setb p2.4
			mov 30H, #4
			call delay_500us
			clr p2.4
			mov 30H, #16
			call delay_500us
		jnb tf1, openDoor_
		clr tr1
		inc 34H
	djnz 33H, openDoor_loop
	call closedoor
	interrupt_closedoor:
ret

closedoor:
	mov 33H, #10
	closeDoor_loop:
		mov tl1, #0FDH 
		mov th1, #04BH
		clr tf1
		setb tr1
		closeDoor_:
			setb p2.4
			mov 30H, #3
			call delay_500us
			clr p2.4
			mov 30H, #17
			call delay_500us
		jnb tf1, closeDoor_
		clr tr1
	djnz 33H, closeDoor_loop
ret

allowRetries3:
	mov 36H, #3
	jnb 44H, retry_loop
	retry_loop:
		call main_display
		call update_countdown_retries
		call get_verified_input
		jb 41H, verified_user
	djnz 36H, retry_loop
		clr EA
		setb P2.3
		mov 30H, #20
		call delay_50ms
		clr P2.3
		setb EA
	jmp unverified_user
	verified_user:
		call main_display
		setb EX0
		setb IT0
		setb 44H
		call opendoor5s
		clr 44H
		clr EX0
unverified_user:
ret

EX0_ISR:
mov 30H, #1
call delay_50ms
setb 42H
inc 32H
call main_display
reti

EX1_ISR:
clr EX1
mov 30H, #1
call delay_50ms
dec 32H
call opendoor5s
call main_display
setb EX1
reti

keypadRead:			
	mov P1,#0    ; port P1 is for rows (output port)
	mov A, P2
	anl A, #11111000B
	add A, #7H
	mov P2, A
	;;;;; keypad info
	rows equ  4
	cols equ  3
	;;;; creating mask for checking columns
	mov a,#0h
	mov R1,#0h
	rot_again: 
		setb c
		inc R1
		rlc	a
	cjne R1,#cols,rot_again
	
	;;;;; start scanning 
	start:
	mov 31H,a    ; mask is in 31H
	again:
		mov R1,#0efh ; ground 0th row
		mov R2,#0
		mov R3,#0
		next_row:
			mov P1,R1 
			mov a,P2
			anl a,31H
			cjne a,31H,key_pressed
			mov a,R1
			rl a
			mov R1,a
			inc R2 				  ; R2 will contain the row index
		cjne R2,#rows,next_row
	jmp again
	
	key_pressed:
	call delay_50ms	  ; debounce time
	again1:
		rrc a
		jnc findkey
		inc R3				; R3 contains the column index
	jmp again1
	
	findkey:
	mov a,#cols
	mov b,R2
	mul ab
	add a,R3
	mov dptr,#key
	movc a,@a+dptr
	mov 40H,a
	
	release_key:
		mov a,P2
		anl a,31H
	cjne a,31H,release_key
	call delay_50ms	  ; debounce time

ret

delay_50ms:							;30H * 50ms Delay
	mov 70H, A
	mov A, 30H
	cjne A, #0, delay50ms_loop
	mov 30H, #1
	delay50ms_loop:
		mov TL0, #0FDH
		mov TH0, #04BH
		clr TF0
		setb TR0
		jnb TF0, $
		clr TR0
	djnz 30H, delay50ms_loop
	mov A, 70H
ret

delay_500us:							;30H * 500us Delay
	mov 70H, A
	mov A, 30H
	cjne A, #0, delay_500us_loop
	mov 30H, #1
	delay_500us_loop:
		mov TL0, #033H
		mov TH0, #0FEH
		clr TF0
		setb TR0
		jnb TF0, $
		clr TR0
	djnz 30H, delay_500us_loop
	mov A, 70H
ret



str_main_display: DB "Code:",0,"People:",0
str_main_display_passwrong: DB "wrong code",0,"attempts left",0
str_main_display_passright: DB "Welcome!",0,"seconds left:",0
str_main_display_maxcap: DB "Room at max",0,"capacity.",0,"please wait for",0,"someone to leave",0
key: db 31H,32H,33H,34H,35H,36H,37H,38H,39H,0,30H,0 ;1D index = column index + (row index * total no. of cols)
passcode: DB "2580",0
end
