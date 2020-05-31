TESTPC    SEGMENT
           ASSUME  CS:TESTPC, DS:NOTHING, ES:NOTHING, SS:NOTHING
START:     JMP     BEGIN

ADDRESS_MEMORY db 'overlay 1 address XXXX',0DH,0AH,'$'

;-----------------------------------------------------
TETR_TO_HEX   PROC  near
           and      AL,0Fh
           cmp      AL,09
           jbe      NEXT
           add      AL,07
NEXT:      add      AL,30h
           ret
TETR_TO_HEX   ENDP
;-------------------------------
BYTE_TO_HEX   PROC  near
; байт в AL переводится в два символа в шестн. числа в AX
           push     CX
           mov      AH,AL
           call     TETR_TO_HEX
           xchg     AL,AH
           mov      CL,4
           shr      AL,CL
           call     TETR_TO_HEX ;в AL старшая цифра
           pop      CX          ;в AH младшая
           ret
BYTE_TO_HEX  ENDP
;-------------------------------
WRD_TO_HEX   PROC  near
;перевод в 16 с/c 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
           push     BX
           mov      BH,AH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           dec      DI
           mov      AL,BH
           call     BYTE_TO_HEX
           mov      [DI],AH
           dec      DI
           mov      [DI],AL
           pop      BX
           ret
WRD_TO_HEX ENDP
;--------------------------------------------------

GET_ADDRESS   PROC  near
			mov ax, cs
			mov bx, offset ADDRESS_MEMORY
			mov di, bx
			add di, 21
			call WRD_TO_HEX
			mov dx, bx
			mov ah,09h
			int 21h	
			ret
GET_ADDRESS  ENDP
;-------------------------------

BEGIN:
			push DS
			mov AX, CS
			mov DS, AX
			call GET_ADDRESS
			pop DS

            retf
TESTPC      ENDS
            END     START