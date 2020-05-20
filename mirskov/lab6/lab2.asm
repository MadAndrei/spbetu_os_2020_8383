TESTPC    SEGMENT
           ASSUME  CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
           ORG     100H
START:     JMP     BEGIN

enter_string db 0DH,0AH,'$'
ADDRESS_MEMORY db 'Unavailable memory segment address XXXX',0DH,0AH,'$'
ADDRESS_ENV db 'Segment address of the environment XXXX',0DH,0AH,'$'

;процедуры
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
			mov ax, [ds:2]
			mov bx, offset ADDRESS_MEMORY
			mov di, bx
			add di, 38
			call WRD_TO_HEX
			mov dx, bx
			mov ah,09h
			int 21h	
			ret
GET_ADDRESS  ENDP
;-------------------------------
GET_ENV   PROC  near
			mov ax, [ds:44]
			mov bx, offset ADDRESS_ENV
			mov di, bx
			add di, 38
			call WRD_TO_HEX
			mov dx, bx
			mov ah,09h
			int 21h	
			ret
GET_ENV  ENDP
;-------------------------------
GET_TAIL   PROC  near
			sub cx, cx
			mov cl, ds:[80h]
			sub si, si
			for:
				cmp cl, 0
				je for_end
				mov es, [ds:81h]
				mov dl, es:[si]
				mov ah,02h
				int 21h	
				inc si
				dec cl
				jmp for
			for_end:
			mov dx, offset enter_string
			mov ah, 09h
			int 21h
			ret
GET_TAIL  ENDP
;-------------------------------
PRINT_ENV   PROC  near
			sub si, si
			begin_label:
				mov es, [ds:2ch]
				mov dx, [es]:si
				inc si
				cmp dl, 0
				je print_enter
				back:
				cmp dx, 1
				je end_label
				mov ah,02h
				int 21h	
				jmp begin_label
			end_label:
				ret
			print_enter:
				push dx
				mov dx, offset enter_string
				mov ah, 09h
				int 21h 
				pop dx
				jmp back
PRINT_ENV  ENDP
;-------------------------------
PRINT_PATH   PROC  near
			add si, 1
			mov es, [ds:2ch]
			begin_label1:
				mov dx, [es]:si
				inc si
				cmp dx, 0
				je end_label1
				mov ah,02h
				int 21h	
				jmp begin_label1
			end_label1:
				mov dx, offset enter_string
				mov ah, 09h
				int 21h 
				ret
PRINT_PATH  ENDP
;-------------------------------

; код

BEGIN:
			call GET_ADDRESS
			call GET_ENV
			call GET_TAIL
			call PRINT_ENV
			call PRINT_PATH

			xor AL, AL
			mov AH, 01h
			int 21h
            mov AH,4Ch
            int 21H
TESTPC      ENDS
            END     START     ;конец модуля, START - точка входа