

;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;Stack Segment
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
STACK_SEG    SEGMENT PARA STACK
    db      64 DUP('DADA007 ')              ;8 * 64 = 512 bytes, used to understand how much of the stack is utilized.
STACK_SEG    ENDS                                    ;If more than 512 bytes are used, the string 'DADA007 ' is overwritten.
                        ;The maximum for each segment is 64 kilobytes.
;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;Variables Segment
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
DATA_SEG    SEGMENT PARA
    ;strings that will be printed on the screen during the execution of the program
    ;note: 13 -> line start, 10 -> line break
        msg1    db      '                         ----> S P A C E - C A R <----',13,10,'$' ;30 CHARACTERS -> 25 SPACES ON THE LEFT TO CENTER
        msg2    db      ' The game consists of dodging asteroids and collecting as many coins',13,10,'$'
        msg2b   db      ' as possible to set a new RECORD!',13,10,'$'
        msg3    db      ' Use the arrow keys (Right and Left) to move',13,10,'$'
        msg4    db      ' Hearts are lives, you can accumulate a maximum of 5',13,10,'$'
        msg5    db      ' Once your lives run out, the game is over',13,10,'$'
        msg6    db      ' Up/Down Arrow:  Increase/Decrease the level (speed)',13,10,'$'
        msgEsc    db      ' ESC:             Exit the game immediately',13,10,'$'
        mPause  db      ' P:               Pause the game',13,10,'$'
        mStart db      ' Press ENTER to start the race',13,10,'$'

        clearStart db      '                                   ','$'        ;to erase mStart without clearing the screen
        exitLabel   db      'Press ENTER to return to DOS      ','$'

        pauseLabel  db      'PAUSE                              ','$'
        gameOverLabel    db      'GAME OVER                          ','$'
        winLabel    db      'You reached the maximum score!     ','$'

        finalScoreLabel  db      'Final score: ','$'
        finalLifeLabel   db      'Remaining lives: ','$'

        deadLabel   db      'YOU CRASHED INTO AN ASTEROID!      ','$'
        keyLabel  db      'Press a key to continue           ','$'
        enterLabel  db      'Press ENTER to continue           ','$'

        mLife   db      'LIFE: ','$'
        mLevel  db      'LEVEL: ','$'
        mScore  db      'SCORE: ','$'

        lLife   db      '+1 LIFE     ','$'
        lScore  db      '+1 SCORE    ','$'
        lLevelU db      '+1 LEVEL    ','$'
        lLevelD db      '-1 LEVEL    ','$'
        life    dw      3       ;3 initial lives
        level   dw      1       ;level 1
        score   dw      0H      ;score 0
        tLevel  dw      10H     ;cycles at the first level 16=10H

        maxScore dw     1000     ;maximum score to end the game

        mssgdb  db      '                   ','$'

    ;variables for Random
        IsFirstExecution  DB     00H           ; First execution flag (= 0 yes; <> 0 no)
        RandomValueLow   DW     ?             ; current 32-bit random number value
        RandomValueHigh   DW     ?
        MultiplierValue DW     8405H         ; Multiplier value

DATA_SEG    ENDS







;=========================================================================================================
 ;---------------------------------------------------------------------------------------------------------
;PROGRAM SEGMENT
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;PROGRAM SEGMENT
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
_prog    SEGMENT  PARA 'CODE'    ;allocation of Code Segment, Stack Segment, and Data Segment
    ASSUME  CS:_prog,        SS:STACK_SEG,        DS:DATA_SEG        ;ASSUME forces the correct use of the segment for all symbols in the segment
    ORG 0100H       ;reserve the first 100H locations
    BEGIN: JMP     Main    ;start from the label Main

    ;=========================================================================================================
    ;KEYS (CONSTANTS)
    ;=========================================================================================================
    ESC_KEY     EQU     1bh             ;ESC key
    ENTER_KEY EQU     0dh             ;ENTER key
    CURSOR_UP     EQU     4800h           ;cursor movement up
    CURSOR_DOWN    EQU     5000h           ;cursor movement down
    CURSOR_RIGHT    EQU     4d00h           ;cursor movement right
    CURSOR_LEFT    EQU     4b00h           ;cursor movement left
    FRAME_RIGHT  EQU     27              ;right limit for the spaceship (right column of the frame)
    FRAME_LEFT_LIMIT  EQU     2               ;left limit for the spaceship (left column of the frame)

;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;MACROS
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================
SET_CURSOR MACRO row,col             ;Macro to choose where to position the Cursor
    PUSH DX
    MOV DH,row             ;row
    MOV DL,col             ;column
    CALL posCur             ;calls the posCur procedure - 02H of INT10H to position the cursor
    POP DX
ENDM
;=========================================================================================================
PRINT_TTY_CHAR MACRO char              ;prints in TTY mode (updates the cursor)
    PUSH AX
    MOV AL,char             ;select the character passed as a parameter
    CALL WRITE_TTY           ;calls the procedure
    POP AX
ENDM
;=========================================================================================================
PRINT_COLOR_CHARS MACRO char,num,col      ;prints n colored characters
    PUSH AX
    PUSH CX
    MOV AL,char             ;select the character passed as a parameter
    MOV CX,num
    MOV BL,col
    CALL WRITE_COLOR           ;calls the procedure
    POP CX
    POP AX
ENDM
;=========================================================================================================
PRINT_BW_CHAR MACRO char             ;prints a character in Black and White
    PUSH AX
    MOV AL,char             ;select the character passed as a parameter
    CALL WRITE_BW            ;calls the procedure
    POP AX
ENDM
;=========================================================================================================
Random  MACRO num       ;remember to PUSH AX if necessary
            ;EX: num=10 the random number goes from 0 to 9
    MOV AX,num      ;inputs the value of AX into the Random procedure
    CALL rand
ENDM
;=========================================================================================================
PRINT_MESSAGE  MACRO msg       ;prints a message saved in memory (Data Segment)
    PUSH AX
    PUSH BX
    PUSH DX
    MOV AX,SEG DATA_SEG
    MOV DS,AX
    MOV DX,OFFSET msg
    MOV AH,09H
    INT 21H
    POP DX
    POP BX
    POP AX
ENDM
;=========================================================================================================
CREATE_DELAY MACRO tick      ;creates a delay (1 tick = 0.55 ms -> 18H ticks = 1 second)
    PUSH CX
    MOV CX,tick
    CALL delay      ;calls the delay procedure based on the clock
    POP CX
ENDM

;=========================================================================================================

;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;BEGIN DEL PROGRAMMA
;---------------------------------------------------------------------------------------------------------
;=========================================================================================================

;NB:    in DX salver?? la posizione della navicella
;       in BX salver?? l'ostacolo/moneta/vita (BL=Tipo)  x=asteroide, v=vita, m=moneta
;       CX ?? il contatore del ciclo
Main:           CALL cls        ;clear screen
        SET_CURSOR 0,0
        PRINT_MESSAGE msg1     ;print instructions on the screen
        SET_CURSOR 2,0
        PRINT_MESSAGE msg2
        PRINT_MESSAGE msg2b
        PRINT_MESSAGE msg3
        PRINT_MESSAGE msg4
        PRINT_MESSAGE msg5
        PRINT_MESSAGE msg6
        PRINT_MESSAGE msgEsc
        PRINT_MESSAGE mPause
        SET_CURSOR 11,1
        PRINT_MESSAGE keyLabel
        CALL outCur
        CALL waitKey    ;wait for a key to continue

Start:          ;every time you hit an asteroid, you restart from here
        CALL cls        ;clear screen
        CALL wBordo     ;draw border

    ;PRINT LIVES
        SET_CURSOR 4,40
        PRINT_MESSAGE mLife
        SET_CURSOR 4,50
        PRINT_COLOR_CHARS 03H,life,04H    ;print hearts

    ;PRINT LEVEL
        SET_CURSOR 6,40
        PRINT_MESSAGE mLevel
        SET_CURSOR 6,50
        PRINT_COLOR_CHARS 09H,level,09H   ;print dots (representing the level number)

    ;PRINT SCORE
        SET_CURSOR 8,40
        PRINT_MESSAGE mScore
        SET_CURSOR 8,50
        MOV AX,score
        CALL word2dec           ;print the score

    ;POSITION THE SPACESHIP AT THE BOTTOM CENTER
        MOV DH,20       ;row
        MOV DL,14       ;column
        CALL setCar     ;position the spaceship


        SET_CURSOR 15,40    ;AREA WHERE MESSAGES ARE PRINTED
        PRINT_MESSAGE mStart  ;start of level, waits for Enter key
        CALL outCur
reqINVIO:       CALL waitKey    ;wait for the Enter key
        CMP AL,ENTER_KEY
        JNE reqINVIO
        SET_CURSOR 15,40
        PRINT_MESSAGE clearStart


        ;CALL outCur    ;hide the cursor
        MOV BX,0000H    ;initialize obstacle/life/coin controller each cycle
Ciclo:          MOV CH,BYTE PTR tLevel   ;set the initial level (speed??)
        MOV CL,0        ;initialize the cycle counter to increment


        CMP CH,CL       ;if the level has changed and
        JBE Continue3   ;CH is less than or equal to CL -> Restart the cycle
                ;without this check, the program might freeze
                ;for example, if CL is 0AH and CH has reached 0BH while the level has changed
                ;JBE = jump below or equal

        PUSH DX
        SET_CURSOR 15,40    ;clear the interactive message
        PRINT_MESSAGE mssgdb   ;from the previous cycle
        POP DX
        CMP BL,'m'      ;if a coin is collected, increment the score
         JE addMon
        CMP BL,'v'
         JE addVita     ;if a heart is collected, increment the lives (unless there are already 5)

Continue3:      JMP AspKey

addMon:         PUSH AX         ;coin collected
         MOV AX,score   ;could also do directly "INC score"
         ;INC AX         ;increment score
         ADD AX,level    ;instead of adding 1, add the level value
         MOV score,AX
         SET_CURSOR 8,50    ;position the cursor in the SCORE area:
         CALL word2dec  ;print the ASCII/decimal value of the score variable
         SET_CURSOR 15,40   ;position the cursor in the MESSAGES area
         PRINT_MESSAGE lScore  ;print +1 SCORE
        POP AX
        MOV BX,0000H    ;initialize obstacle/life/coin controller
        JMP AspKey

addVita:        CMP life,5      ;heart collected
        JAE life5       ;if lives are greater than or equal to 5, don't add more lives
        PUSH AX
         MOV AX,life
         INC AX         ;increment the life variable
         MOV life,AX
         SET_CURSOR 4,50    ;set the cursor in the LIFE area:
         PRINT_COLOR_CHARS 03H,life,04H   ;print as many red hearts as lives
         SET_CURSOR 15,40   ;position the cursor in the MESSAGES area
         PRINT_MESSAGE lLife   ;print +1 LIFE
        POP AX
life5:          MOV BX,0000H    ;initialize obstacle/life/coin controller
        JMP AspKey


AspKey:
        CMP BL,'x'      ;check if an asteroid is hit
        JE Dead2        ;if hit -> jump to Dead2
        CALL setCar     ;check if hit an obstacle or collected a coin/heart, then position the spaceship
        CREATE_DELAY 01H     ;18 "waits" per second
        INC CL          ;increment the 18 wait counter
        CMP CL,CH       ;if CL=CH, then the cycle is over (18 waits passed if the cycle is one second long)
        JE Continue2    ;continue to the next line
        CALL pressKey   ;otherwise, check if a key is pressed
        JZ AspKey        ;if no key is pressed, wait again
         CALL waitKey    ;otherwise, check which key was pressed
         CMP AL,ESC_KEY    ;pressed ESC
         JE  Esci2       ;exit to DOS
         CMP AL,'P'      ;pressed P
         JE I_Pause      ;pause the game
         CMP AL,'p'      ;pressed p (lowercase)
         JE I_Pause      ;pause the game
         CMP AX,CURSOR_RIGHT      ;pressed Right arrow - CURSOR_RIGHT EQU 4D00H
         JE Destra2
         CMP AX,CURSOR_LEFT      ;pressed Left arrow - CURSOR_LEFT EQU 4B00H
         JE Sinistra2
         CMP AX,CURSOR_UP     ;pressed Up arrow
         JE Su2
         CMP AX,CURSOR_DOWN     ;pressed Down arrow
         JE Giu2
         ;CMP AL,'h'      ;INCREASE SCORE BY 100
         ;JE HintA2
         ;CMP AL,'H'      ;DECREASE SCORE BY 100
         ;JE HintB2
         JMP Tasto2      ;go to print the key pressed


;----------labels for JUMP too long-------------
;Win2:           JMP Win
Dead2:          JMP Dead
Destra2:        JMP Destra
Sinistra2:      JMP Sinistra
Esci2:          JMP Esci
Continue2:      JMP Continue
Tasto2:         JMP Tasto
Su2:            JMP Su
Giu2:           JMP Giu
;HintA2:         JMP HintA
;HintB2:         JMP HintB
;AspKey2:        JMP AspKey
;------------labels for JUMP too long-----------



;-----Pause Management------------------------------
I_Pause:        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        SET_CURSOR 15,40    ;Write "PAUSE" in the MESSAGE area
        PRINT_MESSAGE pauseLabel
Pause:          CALL waitKey    ;Wait for a key
        CMP AL,ESC_KEY      ;ESC key
        JE Esci2         ;Go to Exit
        CMP AL,'P'      ;P key
        JE F_Pause       ;End the Pause
        CMP AL,'p'      ;p key
        JE F_Pause       ;End the Pause
        JMP Pause       ;Otherwise, continue the pause -> loop Pause
F_Pause:        SET_CURSOR 15,40    ;Clear the "PAUSE" text
        PRINT_MESSAGE mssgdb
        POP DX
        POP CX
        POP BX
        POP AX
        JMP AspKey      ;Go to AspKey
;-----Pause Management-------------------------------

AspKey2:        JMP AspKey

Destra:         ;Move the spaceship to the right
        CMP DL,FRAME_RIGHT    ;Check if the spaceship has reached the right edge
        JE AspKey2      ;If it has reached the right limit and I want to move it further right, the program will block it here
         INC DX         ;Otherwise, I can move it right by one character
         PUSH DX
         SUB DX,2       ;Move the cursor to the area where the spaceship was before moving right
         CALL posCur
         PRINT_BW_CHAR ' '   ;Put a space character where the spaceship was before
         POP DX
    ;Print control characters
        ;PUSH DX
        ;SET_CURSOR 21,35
        ;PRINT_BW_CHAR 'R'
        ;SET_CURSOR 21,36
        ;PRINT_BW_CHAR CL
        ;POP DX
    ;End control character printing
        JMP AspKey      ;Wait for the next key

Sinistra:       ;Move the spaceship to the left
        CMP DL,FRAME_LEFT_LIMIT   ;Check if the spaceship has reached the left edge
        JE AspKey2      ;If it has reached the left limit and I want to move it further left, the program will block it here
         DEC DX         ;Otherwise, I can move it left by one character
         PUSH DX
         ADD DX,2       ;Move the cursor to where the spaceship was before being moved left
         CALL posCur
         PRINT_BW_CHAR ' '   ;Put a space character where the spaceship was before
         POP DX
    ;Print control characters
        ;PUSH DX
        ;SET_CURSOR 21,35
        ;PRINT_BW_CHAR 'L'
        ;SET_CURSOR 21,36
        ;PRINT_BW_CHAR CL
        ;POP DX
    ;End control character printing
        JMP AspKey      ;Wait for the next key

Su:             ;Up one level
        CMP level,8     ;Check if we are at level 8
        JAE level8      ;If the level is greater than or equal to 8, don't add more levels
         PUSH AX
         MOV AX,level   ;Otherwise, add a level
         INC AX
         MOV level,AX
          MOV AX,tLevel ;Decrease the cycle duration by 2 ticks
          SUB AX,2
          MOV tLevel,AX
         SET_CURSOR 6,50    ;Position the cursor in the LEVEL zone:
         PRINT_COLOR_CHARS 09H,level,09H  ;Print the level number (blue dots)
         SET_CURSOR 15,40   ;Position the cursor in the MESSAGES zone
         PRINT_MESSAGE lLevelU ;Print +1 LEVEL
        POP AX
level8:          MOV BX,0000H    ;Initialize the obstacle/life/coin controller
        JMP aspKey

Giu:            ;Down one level
        CMP level,1
        JBE level1  ;If the level is less than or equal to 1, don't decrease the level
        PUSH AX
         MOV AX,level
         DEC AX     ;Otherwise, decrease the level
         MOV level,AX
          MOV AX,tLevel ;Increase the cycle duration by 2 ticks
          ADD AX,2
          MOV tLevel,AX
         SET_CURSOR 6,50
         PRINT_MESSAGE mssgdb  ;Clear the previous levels to print fewer dots (otherwise the level decrement won't be visible)
         SET_CURSOR 6,50    ;Position the cursor in the LEVEL zone:
         PRINT_COLOR_CHARS 09H,level,09H  ;Print the level number (blue dots)
         SET_CURSOR 15,40   ;Position the cursor in the MESSAGES zone
         PRINT_MESSAGE lLevelD ;Print -1 LEVEL
        POP AX
level1:          MOV BX,0000H    ;Initialize the obstacle/life/coin controller
        JMP aspKey

Tasto:          ;If I press any key, nothing happens
        ;Leave the label for future use if I want to use other keys
        ;or want the program to do something with generic keys
        ;Print control characters
        ;PUSH DX
        ;SET_CURSOR 20,35
        ;PRINT_BW_CHAR AL
        ;POP DX
        JMP AspKey

Continue:       CALL goGIU      ;Make the obstacles "fall" by one row
        ;Now draw the new obstacles/life/coin (with different probabilities)
        Random 99      ;Random number between 0 and 99 (100 total numbers)
        CMP AX,95
         JAE Vita        ;Greater than or equal to 95 -> life (5% chance)
        CMP AX,25
         JB Moneta      ;Less than 25 -> coin (25% chance)
        CALL wOst       ;Otherwise -> print an obstacle (the remaining 73% chance)
        JMP Next

Vita:           CALL wLife      ;Print a life
        JMP Next
Moneta:         CALL wMon       ;Print a coin
        JMP Next

Dead:           ;PUSH AX
        ;MOV AX,life
        ;DEC AX
        ;MOV life,AX
        ;POP AX
        DEC life        ;Decrease a life
        CMP life,0      ;If life is zero -> Game Over
        JE Lose
         CALL setCar    ;Otherwise, restart the game with one less life
         PUSH DX
         SET_CURSOR 4,50            ;Position the cursor in the LIFE zone:
         PRINT_COLOR_CHARS 03H,life,04H   ;Update the number of hearts
         SET_CURSOR 15,40           ;Position the cursor in the MESSAGES zone
         PRINT_MESSAGE deadLabel           ;Print the message "You hit an asteroid"
         SET_CURSOR 16,40
         PRINT_MESSAGE enterLabel          ;Print "Press enter to continue"
         POP DX

aspINVIO:        CALL waitKey           ;Wait for the ENTER key
        CMP AL,ENTER_KEY           ;To restart the game with one less life
        JNE aspINVIO
        JMP Start

Next:           CALL outCur     ;Hide the cursor

        PUSH AX         ;Check if I've reached the maximum score
        MOV AX,maxScore ;Can't compare two variables directly
        CMP score,AX    ;So, I put one of them into AX
        POP AX
        JAE Win

        JMP Ciclo       ;Continue with the Loop and go to the Ciclo label

Lose:           ;CALL cls
        PUSH DX
        SET_CURSOR 15,40    ;Position the cursor in the MESSAGES zone
        PRINT_MESSAGE gameOverLabel    ;Print "GAME OVER"
        POP DX
        CALL setCar
        JMP Exit

Win:            PUSH DX
        SET_CURSOR 15,40
        PRINT_MESSAGE winLabel
        POP DX
        CALL setCar

Exit:           SET_CURSOR 17,40
        PRINT_MESSAGE finalScoreLabel   ;Print the final score
        SET_CURSOR 17,59    ;Zone for the score value
        PUSH AX
        MOV AX,score
        CALL word2dec   ;Convert the score to decimal value
        POP AX
        ;POP DX
        CALL waitKey    ;Wait for a key

Esci:           SET_CURSOR 19,40
        PRINT_MESSAGE exitLabel    ;Print the exit message
waitINV:        CALL waitKey    ;Wait for ENTER to exit
        CMP AL,ENTER_KEY
        JNE waitINV
        CALL cls
        CALL tornaDOS   ;Call the procedure to return to DOS


;=========================================================================================================
;---------------------------------------------------------------------------------------------------------
;PROCEDURE
;---------------------------------------------------------------------------------------------------------
;============================================================================
wBordo PROC NEAR        ; Draw the border where the game is played
        ; PRINT TOP LINE
        SET_CURSOR 0,0      ; Position cursor at the top left
        PRINT_TTY_CHAR 0DAH    ; Print the top left corner
        MOV CX,28       ; Set loop to 28 iterations (columns)
CicloR1:        PRINT_TTY_CHAR 0C4H    ; Print the top line
        LOOP CicloR1    ; Repeat until reaching column 29
        PRINT_TTY_CHAR 0BFH    ; Print the top right corner

        ; PRINT LEFT COLUMN
        MOV DH,01H      ; Set row to 2
        MOV DL,00H      ; Set column to 0 (fixed) - first column
        MOV CX,20       ; Set loop to 20 iterations (rows)
CicloC1:        CALL posCur     ; Position cursor at DH,DL (row,column)
        PRINT_TTY_CHAR 0B3H    ; Print the character | for the left column
        inc DH          ; Increment the counter (move to the next row)
        LOOP CicloC1    ; Repeat 20 times

        ; PRINT RIGHT COLUMN
        MOV DH,01H      ; Set row to 2
        MOV DL,29       ; Set column to 29 (fixed) - 30th column
        MOV CX,0020     ; Set loop to 20 iterations (rows)
CicloC2:        CALL posCur     ; Position cursor at DH,DL (row,column)
        PRINT_TTY_CHAR 0B3H    ; Print the character | for the right column
        inc DH          ; Increment the counter (move to the next row)
        LOOP CicloC2    ; Repeat 20 times

        ; PRINT BOTTOM LINE
        SET_CURSOR 21,0     ; Position cursor at row 22, column 0
        PRINT_TTY_CHAR 0C0H    ; Print the bottom left corner
        MOV CX,28       ; Set loop to 28 iterations (columns)
CicloR2:        PRINT_TTY_CHAR 0C4H    ; Print the hyphen to form the line
        LOOP CicloR2    ; Repeat 28 times
        PRINT_TTY_CHAR 0D9H    ; Print the bottom right corner

        ; I HAVE CREATED A RECTANGLE OF 22 ROWS X 30 COLUMNS

wBordo ENDP
;============================================================================
rand PROC NEAR        ; Function that generates a random number between 0 < n < AX
    OR      AX,AX           ; If the value of the range passed as a parameter
    JNZ     Rand_1          ; is not zero, it imposes an immediate end of the
    RET                     ; procedure (incorrect value!)

Rand_1: PUSH    BX          ; Save registers used by the procedure
    PUSH    CX
    PUSH    DX
    PUSH    DI
    PUSH    DS
    PUSH    AX              ; Save the range value passed as input
                            ; (will be used at the end)
    LEA     DI,IsFirstExecution      ; Check if this is the first call
    CMP Byte Ptr DS:[DI],00H  ; of the procedure that generates the delay.
    JNE     Rand_2          ; If NOT, calculate the new value

    MOV     AH,2CH          ; If it's the first call, the procedure
    INT     21H             ; takes a random value from the
    MOV     DS:[RandomValueLow],CX  ; CMOS memory that contains the current time.
    MOV     DS:[RandomValueHigh],DX  ; It uses DOS Function 2CH which
                            ; leaves CH = Hours     (0-23)
                            ;               in CL = Minutes  (0-59)
                            ;       in DH = Seconds (0-59)
                            ;       in DL = Hundredths of a second (0-99)
    MOV Byte Ptr DS:[DI],01H  ; Modify the byte of first input to avoid
                            ; reloading the initial random variables

                            ; Instructions for the first cycle
Rand_2: MOV     AX,DS:[RandomValueLow]  ; AH=Hours     (0-23), AL=Minutes    (0-59)
    MOV     BX,DS:[RandomValueHigh]  ; BH=Seconds (0-59), BL=Hundredths (0-99)
    MOV     CX,AX           ; CH=Hours     (0-23), CL=Minutes    (0-59)

    MUL     DS:[MultiplierValue]   ; AX*Constant=AX*8405H=DX,AX (32-bit number)

    SHL     CX,1            ; Random number calculation algorithm
    SHL     CX,1
    SHL     CX,1
    ADD     CH,CL
    ADD     DX,CX
    ADD     DX,BX
    SHL     BX,1
    SHL     BX,1
    ADD     DX,BX
    ADD     DH,BL
    MOV     CL,5
    SHL     BX,CL
    ADD     AX,1
    ADC     DX,0

    MOV     DS:[RandomValueLow],AX  ; Save the 32-bit result of the manipulation
    MOV     DS:[RandomValueHigh],DX  ; in the designated variables

    POP     BX              ; Restore BX with the range value passed in
                            ; input, in AX
    XOR     AX,AX           ; Prepare the 32-bit dividend by forcing it to zero
    XCHG    AX,DX           ; the 16 most significant bits and copying into
                            ; the 16 least significant bits the current value of DX
    DIV     BX              ; AX = quotient (DX,AX / BX)
                            ; DX = remainder
    XCHG    AX,DX           ; the current random number is the remainder value
                            ; and is left, as output, in AX
    POP     DS
    POP     DI              ; Restore the registers used by the procedure
    POP     DX
    POP     CX
    POP     BX
    RET
rand ENDP

;============================================================================
delay PROC NEAR         ; CX=18 to have 0.55ms * 18 = 1 second delay
    PUSH AX         ; save registers
    PUSH BX
    PUSH DX

    PUSH CX         ; put the value of CX in BX
    POP BX          ; now BX contains the chosen delay value
    CALL clock      ; returns the system time in CX, DX (32-bit)
    ADD DX, BX      ; add a certain number of TICKS (CX) to DX (lower part of the time)
    JNC Delay_0     ; if no carry, jump to Delay_0
    INC CX          ; otherwise, add the carry to CX
Delay_0: 
    PUSH CX         ; copy in AX, BX the number of Ticks from the first reading
    PUSH DX         ; UPDATED with the number corresponding to the desired DELAY
    POP BX          ; effectively, in AX, BX I have the future time to reach
    POP AX
Delay_1: 
    PUSH AX         ; save AX, BX (time to reach) on the stack
    PUSH BX
    CALL clock      ; save the new time reading in CX, DX
    POP BX          ; and AX, BX still have the time to reach
    POP AX

    CMP AX, CX      ; compare the high part of both times
    JZ Delay_2      ; if they are the same, check the lower part (Delay_2)
            ; otherwise, it means they (almost always) differ by the carry
    PUSH AX         ; save the high part
    SUB AX, CX      ; check if they differ, possibly by a number other than 1
    CMP AX, 18H     ; if the difference is 18H, midnight has passed
    POP AX
    JNZ Delay_1     ; if midnight hasn't passed, return to Delay_1 to continue waiting

    PUSH BX         ; if midnight has passed (the difference is 18H)
    SUB BX, 00B0H   ; so CX, DX has gone from 0018-00AFH to 0000-0000H
    CMP BX, DX      ; now, adjust the lower part of the time to the new situation
    POP BX
    JG Delay_1      ; if BX, DX is still greater, continue waiting
    JMP Delay_3     ; otherwise, no need to wait further - delay is over!

Delay_2: 
    CMP BX, DX      ; if the high part is the same and the lower part of the
    JG Delay_1      ; current time is smaller, BX > DX -> continue waiting

Delay_3: 
    POP DX          ; the delay is over!
    POP BX
    POP AX

    RET             ; return

delay ENDP
;=========================================================================================================
wLife PROC NEAR         ; prints a random heart
    PUSH DX
    PUSH CX
    PUSH BX
    PUSH AX
    Random 27       ; random column between 0 and 27 (value in AX)
    INC AX          ; random column between 1 and 28 (inside the frame)
    SET_CURSOR 1, AL    ; choose the lower part of the random number (because the upper part is 0)
    MOV BH, 0       ; video page 0
    MOV CX, 1       ; choose to print one character
    MOV AL, 03H     ; choose the character (Heart)
    MOV BL, 04H     ; choose red on black color
    CALL scrivi     ; print the character
    POP AX
    POP BX
    POP CX
    POP DX
    RET
wLife ENDP
;=========================================================================================================
wMon PROC NEAR       ; prints a random coin
    PUSH DX
    PUSH CX
    PUSH BX
    PUSH AX
    Random 27       ; random column between 0 and 27 (value in AX)
    INC AX          ; random column between 1 and 28 (inside the frame)
    SET_CURSOR 1, AL    ; choose the lower part of the random number (because the upper part is 0)
    MOV BH, 0       ; video page 0
    MOV CX, 1       ; choose to print one character
    MOV AL, 0FH     ; choose the character (Coin - Sun)
    MOV BL, 0EH     ; choose yellow on black color
    CALL scrivi     ; print the character
    POP AX
    POP BX
    POP CX
    POP DX
    RET
wMon ENDP
;=========================================================================================================
wOst PROC NEAR       ; prints a random obstacle
    PUSH DX
    PUSH CX
    PUSH BX
    PUSH AX
    Random 27       ; random column between 0 and 27 (value in AX)
    INC AX          ; random column between 1 and 28 (inside the frame)
    SET_CURSOR 1, AL    ; choose the lower part of the random number (because the upper part is 0)
    MOV BH, 0       ; video page 0
    MOV CX, 1       ; choose to print one character
    MOV AL, 0B1H    ; choose the character (A "rock")
    MOV BL, 08H     ; choose gray on black color
    CALL scrivi     ; print the character
    POP AX
    POP BX
    POP CX
    POP DX
    RET             ; return
wOst ENDP
;============================================================================
goGIU PROC NEAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AH, 07H      ; function to move part of the screen down
    MOV AL, 01H      ; number of rows
    MOV CH, 1        ; top-left row
    MOV CL, 1        ; top-left column
    MOV DH, 20       ; bottom-right row
    MOV DL, 28       ; bottom-right column
            ; from 1,1 to 28,20 (the frame is on rows 0 and 22)
    MOV BH, 07H      ; empty rows color black (DEFAULT 07H)
    INT 10H
    POP DX
    POP CX
    POP BX
    POP AX
    RET             ; return
goGIU ENDP

;=========================================================================================================
WRITE_TTY PROC Near      ;AL=char, CX=number of times
    PUSH BX
    MOV BH,00H      ;Page 0
    MOV BL,70H      ;White on black
    MOV AH,0EH      ;Function 0EH of INT 10H (Displays one or more colored characters on the screen)
    INT 10H
    POP BX
    RET             ;Returns
WRITE_TTY ENDP
;=========================================================================================================
WRITE_COLOR PROC Near      ;AL=char, CX=number of times, BL=color
    MOV BH,00H      ;Page 0
    MOV AH,09H      ;Function 09H of INT 10H (Displays one or more colored characters on the screen)
    INT 10H
    RET             ;Returns
WRITE_COLOR ENDP
;=========================================================================================================
WRITE_BW PROC Near      ;AL=char, CX=number of times
    PUSH BX
    PUSH CX
    MOV BH,00H      ;Page 0
    MOV BL,70H      ;White on Black
    MOV CX,1        ;Print ONE character
    MOV AH,0AH      ;Function 0AH of INT 10H (Displays one or more characters on the screen)
    INT 10H
    POP CX
    POP BX
    RET             ;Returns
WRITE_BW ENDP
;=========================================================================================================
scrivi PROC Near     ;AL=char, CX=number of times, BL=color
    MOV AH,09H      ;Function 09H of INT 10H (Displays CX colored characters on the screen)
    INT 10H
    RET             ;Returns
scrivi ENDP
;=========================================================================================================
clock PROC NEAR         ;Puts the current time in the registers:
    MOV AH,00H      ;CX=high part of the clock
    INT 1AH         ;DX=low part of the clock
    RET
clock ENDP
;=========================================================================================================
waitKey PROC NEAR       ;Wait for a key press
    MOV AH,00H      ;Function 00H of INT 16H that waits for a key
    INT 16H
            ;AL=ASCII code, AH=scan code
    RET             ;Returns
waitKey ENDP
;============================================================================
pressKey PROC NEAR
    MOV AH,01H      ;If a key is pressed, modifies the ZERO FLAG
    INT 16H
    RET
pressKey ENDP
;============================================================================
posCur PROC Near     ;Procedure that positions the cursor
    PUSH AX
    PUSH BX
    PUSH DX
    MOV BH,00H      ;Video page 0 (the visible one)
    MOV AH,02H      ;Function 02H of INT 10H that positions the cursor in DH, DL (row, column)
    INT 10H
    POP DX
    POP BX
    POP AX
    RET             ;Returns
posCur ENDP
;============================================================================
setCar PROC NEAR        ;DH=row, DL=column
    PUSH AX
    PUSH CX
    PUSH DX
    MOV CX,0000H

    CALL posCur     ;position the cursor
    CMP BX,0000H   ;if BX == zero then nothing has been touched yet
    JNE asd1       ;skip the check
    CALL checkCar   ;check if something has been touched
asd1:    CALL posCur
    PRINT_BW_CHAR 254    ;I can print the central character

    INC DX          ;move to the right
    CALL posCur
    CMP BX,0000H   ;if BX == zero then nothing has been touched yet
    JNE asd2       ;skip the check
    CALL checkCar
asd2:   CALL posCur
    PRINT_BW_CHAR '|'    ;print the right character

    SUB DX,2        ;move 2 positions to the left
    CALL posCur
    CMP BX,0000H   ;if BX == zero then nothing has been touched yet
    JNE asd3       ;skip the check
    CALL checkCar
asd3:   CALL posCur
    PRINT_BW_CHAR '|'    ;I can print the left character

    ;PRINT CHARACTER FOR DEBUGGING
    ;PUSH DX
    ;SET_CURSOR 18,60    ;print the obstacle I touched
    ;PRINT_BW_CHAR CH
    ;POP DX

    CMP CH,'M'      ;I picked up a coin
    JE Moneta_2
    CMP CH,'X'      ;I picked up a boulder
    JE Masso_2
    CMP CH,'V'      ;I picked up a life
    JE Vita_2
    JMP CONT_2

Moneta_2: JMP CONT_2    ;leave the code as is in case I want to make further changes

Masso_2:  JMP CONT_2

Vita_2:   JMP CONT_2


CONT_2: INC DX
    CALL posCur

    POP DX
    POP CX
    POP AX
    RET                     ;return
setCar ENDP
;============================================================================
checkCar PROC NEAR ;DH=row, DL=column
    CMP CL,01H      ;CL checks if something has already been picked up
    JE CONT_1       ;CL=1 skip the check since it's not needed and go to the end

    CALL readCur    ;check the ASCII character pointed by the cursor AL=character, AH=color
    CMP AH,08H      ;if it's gray -> boulder
    JE Masso_1
    CMP AH,0EH      ;if it's yellow -> coin
    JE Moneta_1
    CMP AH,04H
    JE Vita_1      ;if it's red -> life
    CMP AH,07H
    JE Niente_1    ;doesn't pick up anything
    JMP CONT_1

Masso_1: MOV CL,01H     ;set CL to 1 to indicate that something has been touched
    MOV CH,'X'     ;store the type of obstacle in CH (it lasts one tick in CH)
    MOV BL,'x'     ;store the type of obstacle in BL (it lasts one cycle in BL)
    JMP CONT_1

Moneta_1: MOV CL,01H    ;set CL to 1 to indicate that something has been touched
    MOV CH,'M'    ;store the type of obstacle in CH (it lasts one tick in CH)
    MOV BL,'m'    ;store the type of obstacle in BL (it lasts one cycle in BL)
    JMP CONT_1

Vita_1:   MOV CL,01H    ;set CL to 1 to indicate that something has been touched
    MOV CH,'V'    ;store the type of obstacle in CH (it lasts one tick in CH)
    MOV BL,'v'    ;store the type of obstacle in BL (it lasts one cycle in BL)
    JMP CONT_1

Niente_1: MOV CH,'_'    ;control character
    JMP CONT_1

CONT_1:   RET

checkCar ENDP

;=========================================================================================================
Word2Dec PROC NEAR      ; Converts the provided hexadecimal word in AX to the corresponding ASCII characters
    PUSH    AX
    PUSH    BX
    PUSH    DX
    CMP     AX,10000        ; If the input hexadecimal number is less than
    JC      Wor2_0          ; 10000, the next division is skipped
    MOV     DX,0000H        ; (DX,AX=0000XXXX):(BX=10000)=AX, remainder DX
    MOV     BX,10000        ; Prepares the divisor as 10000
    DIV     BX              ; Executes the division
    CALL    STAasci         ; Prints the value of Ten Thousands
    MOV     AX,DX           ; Moves the remainder RRRR of the division into AX
    JMP     SHORT Wor2_1    ; Proceed to divide the previous value in the next phase
Wor2_0: CMP     AX,1000     ; If the input hexadecimal number is less than
    JC      Byt2_0          ; 1000, the next division is skipped
Wor2_1: MOV     DX,0000H    ; (DX,AX=0000XXXX):(BX=1000)=AX, remainder DX
    MOV     BX,1000         ; Prepares the divisor as 1000
    DIV     BX              ; Executes the division
    CALL    STAasci         ; Prints the value of Thousands
    MOV     AX,DX           ; Moves the remainder RRRR of the division into AX
    JMP     SHORT Byt2_1    ; Proceed to divide the previous value in the next phase

; Byte2Dec
    PUSH    AX              ; Saves the registers used by the procedure, including the value to be converted, passed in AL
    PUSH    BX              ; and passed as input in AL
    PUSH    DX              ; 
    MOV     AH,00H          ; Formats the dividend to AX=00XX
Byt2_0: CMP     AX,100      ; If the input hexadecimal number is less than
    JC      Byt2_2          ; 100, the next division is skipped
Byt2_1: MOV     BL,100      ; Prepares the divisor as 100
    DIV     BL              ; Divides AX=00XX by BL=100 (AX:BL=AL, remainder AH)
    CALL    STAasci         ; Prints the value of Hundreds
    MOV     AL,AH           ; Moves the remainder RR from the previous division into AL
    MOV     AH,00H          ; Prepares the dividend for the next phase, formatting it as AX=00RR
    JMP     SHORT Byt2_3    ; 
Byt2_2: CMP     AX,10       ; If the input hexadecimal number is less than
    JC      Byt2_4          ; 10, the next division is skipped
Byt2_3: MOV     BL,10       ; Prepares the divisor as 10
    DIV     BL              ; Divides AX=00XX by BL=10 (AX:BL=AL, remainder AH)
    CALL    STAasci         ; Prints the value of Tens
    MOV     AL,AH           ; Prepares the value in AL for the Units
Byt2_4: CALL    STAasci     ; Prints the value of Units
    POP     DX
    POP     BX
    POP     AX
    RET
Word2Dec ENDP
;========================================================================================================
STAasci PROC NEAR             ; Prints the ASCII value of the number in AL
    PUSH    AX
    ADD     AL,30H        ; Adds 30H to the number to get the ASCII character of the number
    PRINT_TTY_CHAR AL
    POP     AX
    RET
STAasci ENDP
;=========================================================================================================
readCur PROC NEAR             ; Reads the value of the ASCII character pointed to by the cursor
    MOV AH,08H
    MOV BH,00H
    INT 10H               ; Returns in AH=Color, AL=Character
    RET
readCur ENDP
;=========================================================================================================
outCur PROC    Near             ; Procedure to hide the cursor from the screen
    PUSH CX                 ; Based on the procedure to resize the cursor (in height)
    PUSH AX                 ; (If bit 5 of CH is 1, the cursor disappears)
    MOV CH,20H              ; Starting pixel line
    MOV CL,00H              ; Final pixel line
    MOV AH,01H
    INT 10H
    POP AX
    POP CX
    RET                     ; Returns
outCur ENDP
;============================================================================
cls PROC Near
    MOV AL,03H              ; Video mode 80 columns x 24 rows
    MOV AH,00H              ; Also creates a clear screen
    INT 10H
    RET
cls ENDP
;============================================================================
tornaDOS PROC NEAR
    MOV AH,4CH
    INT 21H
tornaDOS ENDP
;============================================================================

_prog    ENDS                   ; END OF PROGRAM SEGMENT
    END     BEGIN          ; End of the program, everything written after is ignored!

