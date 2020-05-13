DATA SEGMENT
	IS_INTERRUPT_SET dw 0
	IS_UN dw 0
	STR_ALREADY_LOADED db 'Already loaded', 0DH, 0AH, '$'
DATA ENDS

ASTACK SEGMENT STACK
	dw 128 dup(?)
ASTACK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK, ES:NOTHING

	INTERRUPT PROC FAR
		jmp START_INTERRUPT
		SIGNATURE dw 1111h
		KEEP_IP dw 0
		KEEP_CS dw 0
		KEEP_PSP dw 0
		KEEP_SP dw 0
		KEEP_SS dw 0
		KEEP_AX dw 0
		REQ_KEY_Z db 2Ch
		REQ_KEY_X db 2Dh
		KEY db 0
		INTERRUPT_STACK dw 128 dup(?)

	  START_INTERRUPT:
	  	mov KEEP_SP, SP
	  	mov KEEP_SS, SS
	  	mov KEEP_AX, AX
	  	mov AX, seg INTERRUPT_STACK
	  	mov SS, AX
	  	mov SP, offset INTERRUPT_STACK
	  	add SP, 256
	  	mov AX, KEEP_AX
	  	push CX
	  	push ES

		in AL, 60h
		cmp AL, REQ_KEY_Z
		je PRESSED_Z
		cmp AL, REQ_KEY_X
		je PRESSED_X

		pushf
		call DWORD PTR CS:KEEP_IP
		jmp INTERRUPT_END

	  PRESSED_Z:
	  	mov KEY, 'X'
	  	jmp DO_REQ
	  PRESSED_X:
	  	mov KEY, 'Z'
	  	jmp DO_REQ

	  DO_REQ:
	  	in AL, 61h
	  	mov AH, AL
	  	or AL, 80h
	  	out 61h, AL
	  	xchg AH, AL
	  	out 61h, AL
	  	mov AL, 20h
	  	out 20h, AL

	  WORK:
	  	mov AH, 05h
		mov CL, KEY
		mov CH, 00h
		int 16h
		or AL, AL
		jz INTERRUPT_END
		mov AX, 0040h
		mov ES, AX
		mov AX, ES:[1Ah]
		mov ES:[1Ch], AX
		jmp WORK

	  INTERRUPT_END:
	  	pop ES
	  	pop CX
	  	mov SS, KEEP_SS
	  	mov SP, KEEP_SP
	  	mov AX, KEEP_AX
		mov AL, 20H
		out 20H, AL
		iret
	INTERRUPT ENDP
  LAST_BYTE:

	CHECK_INTERRUPT_SET PROC
		push AX
		push BX
		push SI
		push DX

		mov AH, 35h
		mov AL, 09h
		int 21h

		mov SI, offset SIGNATURE
		sub SI, offset INTERRUPT
		mov AX, ES:[BX + SI]
		cmp AX, 1111h
		jne CHECK_INTERRUPT_END
		mov IS_INTERRUPT_SET, 1
		cmp IS_UN, 1
		je CHECK_INTERRUPT_END
		mov DX, offset STR_AlREADY_LOADED
		call PRINT_STR

	  CHECK_INTERRUPT_END: 
	  	pop DX
	  	pop AX
	  	pop BX
	  	pop SI
		ret
	CHECK_INTERRUPT_SET ENDP

	CHECK_UN PROC
		push ES
		push AX

		mov AX, KEEP_PSP
		mov ES, AX
		cmp byte ptr es:[82h], '/'
		jne FALSE
		cmp byte ptr es:[83h], 'u'
		jne FALSE
		cmp byte ptr es:[84h], 'n'
		jne FALSE

		mov IS_UN, 1

	  FALSE: 
		pop AX
		pop ES
		ret
	CHECK_UN ENDP

	LOAD_INTERRUPT PROC
		push AX
		push BX
		push CX
		push DX
		push DS
		push ES

		mov AH, 35h
		mov AL, 09h
		int 21h
		mov KEEP_IP, BX
		mov KEEP_CS, ES

		mov DX, offset INTERRUPT
		mov AX, seg INTERRUPT
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
		int 21h

		mov DX, offset LAST_BYTE
		add DX, 256h
		mov CL, 4
		shr DX, CL
		inc DX
		xor AX, AX
		mov AH, 31h
		int 21h

		pop ES
		pop DS
		pop DX
		pop CX
		pop BX
		pop AX
		ret
	LOAD_INTERRUPT ENDP

	UNLOAD_INTERRUPT PROC
		CLI
		push AX
		push BX
		push DX
		push SI
		push DS
		push ES

		mov AH, 35h
		mov AL, 09h
		int 21h

		mov SI, offset KEEP_IP
		sub SI, offset INTERRUPT
		mov DX, ES:[BX + SI]
		add SI, 2
		mov AX, ES:[BX + SI]
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
		int 21h

		add SI, 2
		mov AX, ES:[BX + SI]
		mov ES, AX
		push ES
		mov AX, ES:[2Ch]
		mov ES, AX
		mov AH, 49h
		int 21h
		pop ES
		mov AH, 49h
		int 21h

		pop ES
		pop DS
		pop SI
		pop DX
		pop BX
		pop AX
		STI
		ret
	UNLOAD_INTERRUPT ENDP

	PRINT_STR PROC
		push AX

		mov AH, 09h
		int 21h

		pop AX
		ret
	PRINT_STR ENDP

	MAIN PROC
		mov AX, DATA
		mov DS, AX
		mov KEEP_PSP, ES

		call CHECK_UN
		call CHECK_INTERRUPT_SET
		cmp IS_INTERRUPT_SET, 1
		je MAIN_UNLOAD
		call LOAD_INTERRUPT
		jmp MAIN_END

	  MAIN_UNLOAD:
	  	cmp IS_UN, 1
	  	jne MAIN_END 
	  	call UNLOAD_INTERRUPT

	  MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h

	MAIN ENDP

CODE ENDS

END MAIN

