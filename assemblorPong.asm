.equ BALL, 0x1000	
.equ PADDLES, 0x1010 		; Paddles Pos

.equ SCORES, 0x1018			; Scores
.equ LEDS, 0x2000			; LEDs Address
.equ BUTTONS, 0x2030		; Buttons Address



####### [ MAIN ] #######
restart:
call initialise
loop:
call clear_leds
call hit_test
call move_ball
;; Someone won
beq v0, zero, follow
call clear_leds
call update_scores
call display_scores
call wait_result
call clear_leds
call initialise
;;
follow:
ldw a0, BALL(zero)
ldw a1, BALL+4(zero)
call set_pixel
call move_paddles
call draw_paddles
call wait_game

br loop

end:
break
##########################


#######[INITIALISE]#######
initialise:
addi t0, zero, 5				;Ball.x			
addi t1, zero, 3				;Ball.y
addi t2, zero, 1				;Velocity (both x, y)
addi sp, zero, 0x1034
stw t0, BALL(zero)				;Store Ball.x
stw t1, BALL+4(zero)			;Store ball.y
stw t2, BALL+8(zero)			;Store velocity.y
stw t2, BALL+12(zero)			;Store velocity.y

;Paddles positions
addi t0, zero, 0
stw t0, PADDLES(zero)
addi t0, zero, 5
stw t0, PADDLES+4(zero)

;Score max
addi t0, zero, 0x3C				;0x3C = 15 
stw t0, SCORES+8(zero)

ret
##########################


#######[Clear LEDS]#######
clear_leds:
add t2, zero, zero
addi t3, zero, 12
			
loop_ClearLeds:
stw zero, LEDS (t2)			; Store the word 0x00000000 at the address t0 + 0x2000 ( into the leds )
addi t2, t2, 4
bne t2, t3, loop_ClearLeds					; For the word from 0 to 2

ret
##########################	


#######[Set Pixel]#######
## ARGS : a0 : x coord
## 		  a1 : y coord

	
set_pixel:
andi t0, a0, 0xF 			; Selection of the right word
ldw t0, LEDS(t0)		

addi t1, a1, 0				; y coord
add t2, zero, zero			; Index of the loop

loopPixel:					; Once we have the word, we have to find the correct bit : we add y + 8 time x
beq t2, a0, endLoopPixel	; if(t2 == x) goto endLoopPixel	
addi t1, t1, 8				; Add 8 times x
addi t2, t2, 1				; Increment the index
br loopPixel

endLoopPixel:
addi t2, zero, 1			; Mask (reuse t2)
sll t2, t2, t1				; Shift of the number found in the loop (y + 8 time x)
or t0, t0, t2				; Change the bit at the position t1 (with the mask with only a one at that position)

andi t1, a0, 0xF			; Address of the right word
stw t0, LEDS(t1)			

ret

##########################	



#######[HIT TEST ]#######
#Use the position stored
## RETURN v0	= 1 if player1 wins 2 if player2 wins 0 otherwise 

hit_test:
;;;SAVE the REGISTER;;;
addi sp, sp, -16
stw s0, 0(sp)
stw s1, 4(sp)
stw s2, 8(sp)
stw s3, 12(sp)
;;;;;;;;;;;;;;;;;;;;;;;


addi v0, zero, 0				; Set v0 to zero ( nobody has won yet )
ldw t1, BALL+8(zero)			; Velocity x
ldw t2, BALL+12(zero)			; Velocity y
ldw t0, BALL(zero)				; Ball.x
ldw t4, BALL+4(zero)			; Ball.y

;When the ball touches the bound left or right
addi t3, zero, 11				; t3 = Max x right
beq t0, t3, xBoundRight			; If Ball.x = 11 goto boundRight => Means that player1 won
beq t0, zero, xBoundLeft		; If Ball.x = 0 goto boundLeft => Means that player2 won
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Check if the ball is near the paddle2
addi t3, zero, 10				; Position x near the paddle2
beq t0, t3, nearPaddle2			; If Ball.x = 10 goto nearpaddle2 
;Check if the ball is near the paddle1
addi t3, zero, 1				; Position x near the paddle1
beq t0, t3, nearPaddle1			; If Ball.x = 1 goto nearpaddle1 

;When the ball touches the bound up or down
yModif:
addi t3, zero, 7				; Max y
beq t4, zero, yBoundUp			;If Ball.y = 0 goto boundUp
beq t4, t3, yBoundDown			;If Ball.y = 7 goto boundDown
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


stopHitTest:
;Load the registers.
ldw s0, 0(sp)
ldw s1, 4(sp)
ldw s2, 8(sp)
ldw s3, 12(sp)
addi sp, sp, 16
ret


nearPaddle2:
ldw s0 ,PADDLES+4(zero)			; Load position paddle 2. Pixel 0
addi s1, s0, 1					; Pixel 1 
addi s2, s0, 2					; Pixel 2

beq s0, t4 , inversex			; if Ball.y= Paddle2.y   inverse velocity x 
beq s1, t4 , inversex			; if Ball.y= Paddle2.y+1 inverse velocity x 
beq s2, t4 , inversex			; if Ball.y= Paddle2.y+2 inverse velocity x

;;Tests for the border of the paddle
;When the ball arrive from the up with Ball.velocity.y = 1
addi t6, zero, 1
bne t2, t6, from_down				; If Ball.velocity.y != 1 check if the ball comes from down
ldw s4, PADDLES+4(zero)			; Load Paddle2.y 		
add t5, t4, t2					; Add velocity.y to check if the paddle is here
beq s4, t5, inverseyx

;When the ball arrive from the down with Ball.velocity.y = -1
from_down:
addi t6, zero, -1
bne t2, t6, yModif				; If ball.velocity.y != -1 leave
ldw s4, PADDLES+4(zero)			; Load Paddle2.y
addi s4, s4, 2					; Check if the ball arriving from the down is near the down of the paddle 		
add t5, t4, t2					; Add velocity.y and Ball.y
beq s4, t5, inverseyx

br yModif


nearPaddle1:
ldw s0,PADDLES(zero)			; Load position paddle 1. Pixel 0
addi s1, s0, 1					; Pixel 1 
addi s2, s0, 2					; Pixel 2

beq s0, t4 , inversex			; if ball.y= Paddle1.y   inverse velocity x 
beq s1, t4 , inversex			; if ball.y= Paddle1.y+1 inverse velocity x 
beq s2, t4 , inversex			; if ball.y= Paddle1.y+2 inverse velocity x 		

;;Tests for the border of the paddle
;When the ball arrive from the up with Ball.velocity.y = 1
addi t6, zero, 1
bne t2, t6, from_down_1			; If Ball.velocity.y != 1 check if the ball comes from down
ldw s4, PADDLES(zero)			; Load Paddle1.y 		
add t5, t4, t2					; Add velocity.y to check if the paddle is here
beq s4, t5, inverseyx

;When the ball arrive from the down with Ball.velocity.y = -1
from_down_1:
addi t6, zero, -1
bne t2, t6, yModif				; If ball.velocity.y != -1 leave
ldw s4, PADDLES(zero)			; Load Paddle1.y
addi s4, s4, 2					; Check if the ball arriving from the down is near the down of the paddle 		
add t5, t4, t2					; Add velocity.y and Ball.y
beq s4, t5, inverseyx

br yModif

inverseyx:
sub t1, zero, t1
stw t1, BALL+8(zero)
sub t2, zero, t2
stw t2, BALL+12(zero)
br stopHitTest

inversex:						;Inverse the velocity x
sub t1, zero, t1
stw t1, BALL+8(zero)
br yModif						;We need to check if the ball is near a bound up or down	


xBoundRight:
;If pos x == 11
;New VERSION : PLAYER1 WINS						;OLD Inverse velocity x  	sub t1, zero, t1			stw t1, BALL+8(zero)
addi v0, zero, 1
br stopHitTest


xBoundLeft:
;If pos x == 0
;New VERSION : PLAYER2 WINS						;OLD Inverse velocity x  	sub t1, zero, t1			stw t1, BALL+8(zero)
addi v0, zero, 2
br stopHitTest


yBoundUp:
;If Ball.y == 0
;Inverse velocity y
sub t2, zero, t2
stw t2, BALL+12(zero)
br stopHitTest


yBoundDown:
;If Ball.y == 7
;Inverse velocity y
sub t2, zero, t2
stw t2, BALL+12(zero)
br stopHitTest

#########################


#######[Move Ball]#######
move_ball:

ldw t0, BALL (zero)				; Pos x
ldw t1, BALL+8 (zero)			; Velocity x
add t0, t0, t1					; Add the velocity x to the position x
stw t0, BALL (zero)

ldw t0, BALL+4 (zero)			; Pos y
ldw t1, BALL+12 (zero)			; Velocity y
add t0, t0, t1					; Add the velocity y to the position y
stw t0, BALL+4 (zero)

ret

########################


						############################
						#		  PADDLES  		   #	
						############################

#######[Move Paddles]#######
move_paddles:


ldw t1, BUTTONS(zero)			; Load the buttons
andi t2, t1, 2				; Only take the 1th bit of buttons
andi t3, t1, 1				; Only take the 0th bit of buttons

addi t7, zero, 5				; Constant (impossible to go > 5 in the y axe ) because the paddle is 3 pixels

ldw t0, PADDLES(zero)			; Pos paddle 1	-> p1.p
beq t3, zero, UP_1
beq t2, zero, DOWN_1

second_paddle:
ldw t0, PADDLES+4(zero)			; Pos paddle 2	-> p2.p
andi t2, t1, 8				; Only take the 3th bit of buttons
andi t3, t1, 4				; Only take the 2th bit of buttons
beq t2, zero, UP_2
beq t3, zero, DOWN_2

move_paddle_end:
ret

UP_1:
beq t0, zero, second_paddle			; if(p1.p == 0) do nothing
addi t0, t0, -1							; else p1.p = p1.p -1
stw t0, PADDLES(zero)
br second_paddle

DOWN_1:
beq t0, t7, second_paddle				; if(p1.p == 0) do nothing
addi t0, t0, 1					; else p1.p = p1.p -1
stw t0, PADDLES(zero)
br second_paddle

UP_2:
beq t0, zero, move_paddle_end			; if(p1.p == 0) do nothing
addi t0, t0, -1					; else p1.p = p1.p -1
stw t0, PADDLES+4(zero)
br move_paddle_end

DOWN_2:
beq t0, t7, move_paddle_end			; if(p1.p == 0) do nothing
addi t0, t0, 1					; else p1.p = p1.p -1
stw t0, PADDLES+4(zero)
br move_paddle_end

############################



#######[Draw Paddles]#######

draw_paddles:
; save ra and s0 registers:
addi sp, sp, -8
stw ra, 0(sp)
stw s0, 4(sp)
; Code

ldw s0, PADDLES(zero)							; Load the first paddle position
add a0, zero, zero								; Set the x position to 0
addi a1, s0, 0									; Set the y position to the address of the paddle
call set_pixel									; Set the pixel
addi a1, s0, 1
call set_pixel
addi a1, s0, 2
call set_pixel


ldw s0, PADDLES+4(zero)							; Load the second paddle position
addi a0, zero, 11								; Set the x position to 11
addi a1, s0, 0									; Set the y position to the address of the paddle
call set_pixel									; Set the pixel
addi a1, s0, 1
call set_pixel
addi a1, s0, 2
call set_pixel

; restore ra and s0 registers and return:
ldw ra, 0(sp)
ldw s0, 4(sp)
addi sp, sp, 8

ret
############################


						############################
						#		  SCORES  		   #	
						############################

#####[DISPLAY SCORES]#######
display_scores:
ldw t1, SCORES(zero)					;Score player1
ldw t2, SCORES+4(zero)					;Score player2

;Selection of the score player1
ldw t0, font_data(t1)
stw t0, LEDS(zero)


ldw t0, separator(zero)
stw t0, LEDS+4(zero)


ldw t0,font_data(t2)
stw t0, LEDS+8(zero)

ret
############################


#####[UPDATE SCORES]#######
; If v0 = 1 player 1 won, if v0 =2,  player 2 won
update_scores:

andi t2, v0, 1
bne t2, zero, Player1_Result				; If t2 !=0 player1 won
br Player2_Result							; else player 2 won 


end_update:
add v0, zero, zero							;Change v0 to 0
ret

Player2_Result:
ldw t0, SCORES+4(zero)						;Take the score of player2	
ldw t4, SCORES+8(zero)						;Max score
add a0, zero, zero
beq t0, t4, displayP2						;If player2.score = Max Score end of the game	
addi t0, t0, 4								
stw	t0, SCORES+4(zero)
br end_update

Player1_Result:
ldw t0, SCORES(zero)						;Take the score of player1
ldw t4, SCORES+8(zero)						;Max score
addi a0, zero, 1
beq t0, t4, displayP1						;If player1.score = Max Score end of the game
addi t0, t0, 4								;Else Update it by adding 4 (for the address)
stw t0, SCORES(zero)						;Store
br end_update

###########################


##########[WAIT]###########

wait_result:

add t1, zero, zero
addi t0, zero, 1
slli t0, t0, 24
loop_wait_r:
addi t1, t1, 1
bne t1, t0, loop_wait_r
ret

wait_game:
addi t0, zero, 1
slli t0, t0, 20
loop_wait_g:
addi t1, t1, 1
bne t1, t0, loop_wait_g
ret


wait_restart:
call clear_leds
addi t4, zero, 0x1C
add t5, zero, zero
add t3, zero, zero

loop_wait_restart:
ldw t3, waitingRound(t5)
stw t3, LEDS+8(zero)
addi t5, t5, 4
call wait_result
bne t4, t5, loop_wait_restart
br restart
##########################

########[DISPLAY]#########
;ARG : a0 : WINNER : 1 player1, 0 player2
displayP2:
ldw t0, player2(zero)
ldw t1, player2 + 4(zero)
ldw t2, player2 + 8(zero)

stw t0, LEDS(zero)
stw t1, LEDS+4(zero)
stw t2, LEDS+8(zero)
stw zero, SCORES(zero)
stw zero, SCORES+4(zero)
br wait_restart

displayP1:
ldw t0, player1(zero)
ldw t1, player1 + 4(zero)
ldw t2, player1 + 8(zero)

stw t0, LEDS(zero)
stw t1, LEDS+4(zero)
stw t2, LEDS+8(zero)
stw zero, SCORES(zero)
stw zero, SCORES+4(zero)
br wait_restart

###########################

waitingRound:
.word 0x80000000
.word 0xC0000000
.word 0xE0000000
.word 0xF0000000
.word 0xF8000000
.word 0xFC000000
.word 0xFE000000
.word 0xFF000000

player1:
.word 0x0609097F
.word 0x42000000
.word 0x0000407F
player2:
.word 0x0609097F
.word 0x51620000
.word 0x00004649

separator:
.word 0x00181800 ; Separator
font_data:
.word 0x7E427E00 ; 0
.word 0x407E4400 ; 1
.word 0x4E4A7A00 ; 2
.word 0x7E4A4200 ; 3
.word 0x7E080E00 ; 4
.word 0x7A4A4E00 ; 5
.word 0x7A4A7E00 ; 6
.word 0x7E020600 ; 7
.word 0x7E4A7E00 ; 8
.word 0x7E4A4E00 ; 9
.word 0x7E127E00 ; A
.word 0x344A7E00 ; B
.word 0x42423C00 ; C
.word 0x3C427E00 ; D
.word 0x424A7E00 ; E
.word 0x020A7E00 ; F