DATA SEGMENT
	BLOCK dw 0
	db 0
	db 0
	db 0

	KEEP_SS dw 0
	KEEP_SP dw 0

	IS_PREPARE_SUCCES db 1

	STR_PREPARE_CODE_7 db 'memory control block destroyed', 0DH, 0AH, '$'
	STR_PREPARE_CODE_8 db 'not enough memory to execute function', 0DH, 0AH, '$'
	STR_PREPARE_CODE_9 db 'invalid memory block address', 0DH, 0AH, '$'

	STR_NOT_COMPLETED_CODE_1 db 'function number is incorrect', 0DH, 0AH, '$'
	STR_NOT_COMPLETED_CODE_2 db 'file not found', 0DH, 0AH, '$'
	STR_NOT_COMPLETED_CODE_5 db 'disk error', 0DH, 0AH, '$'
	STR_NOT_COMPLETED_CODE_8 db 'insufficient memory', 0DH, 0AH, '$'
	STR_NOT_COMPLETED_CODE_10 db 'invalid string environment', 0DH, 0AH, '$'
	STR_NOT_COMPLETED_CODE_11 db 'invalid format', 0DH, 0AH, '$'

	STR_COMPLETED_CODE_0 db 0DH, 0AH,'normal termination with code      ', '$'
	STR_COMPLETED_CODE_1 db 0DH, 0AH,'CTRL + BREAK termination', '$'
	STR_COMPLETED_CODE_2 db 0DH, 0AH,'device error termination', '$'
	STR_COMPLETED_CODE_3 db 0DH, 0AH,'termination by function 31h', '$'
	STR_FILE_PATH db '                               ', 0DH, 0AH, '$'
	;TODO otstup
DATA ENDS

ASTACK SEGMENT STACK
	dw 128 dup(?)
ASTACK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK, ES:NOTHING

	PRINT_STR PROC
		push AX

		mov AH, 09h
		int 21h

		pop AX
		ret
	PRINT_STR ENDP

	PREPARE_MEM PROC
		push AX
		push BX
		push CX

		; TODO how much memory
		mov BX, offset LAST_BYTE
		mov AX, ES
		;sub BX, AX
		add BX, 800h
		mov CL, 4
		shr BX, CL

		mov AX, 4A00h
		int 21h
		jnc PREPARE_MEM_END

	  	mov IS_PREPARE_SUCCES, 0
	  	cmp AX, 7
	  	je PREPARE_CODE_7
	  	cmp AX, 8
	  	je PREPARE_CODE_8
	  	cmp AX, 9
	  	je PREPARE_CODE_9

	  PREPARE_CODE_7:
	  	mov DX, offset STR_PREPARE_CODE_7
	  	call PRINT_STR
	  	jmp PREPARE_MEM_END
	  PREPARE_CODE_8:
	    mov DX, offset STR_PREPARE_CODE_8
	    call PRINT_STR
	    jmp PREPARE_MEM_END
	  PREPARE_CODE_9:
	  	mov DX, offset STR_PREPARE_CODE_9
	  	call PRINT_STR

	  PREPARE_MEM_END:
		pop CX
		pop BX
		pop AX
		ret
	PREPARE_MEM ENDP

	LOAD_PROGRAM PROC
		push AX
		push BX
		push DX
		push ES
		push SI
		push DI

		mov BX, offset BLOCK
		mov AX, 0h
		mov [BX+0], AX
		mov [BX+2], ES
		mov AX, 80h
		mov [BX+4], AX
		mov [BX+6], ES
		mov AX, 5Ch
		mov [BX+8], AX
		mov [BX+10], ES
		mov AX, 6Ch
		mov [BX+12], AX

		mov ES, ES:[2Ch]
		xor SI, SI
	  LABEL1:
	  	mov AX, ES:[SI]
	  	inc SI
	  	cmp AX, 0h
	  	jne LABEL1
	  	add SI, 3
	  	mov DI, offset STR_FILE_PATH

	  LABEL2:
	  	mov AL, ES:[SI]
	  	cmp AL, 0h
	  	je LABEL_END
	  	mov [DI], AL
	  	inc DI
	  	inc SI
	  	jmp LABEL2

	  LABEL_END:
	  	mov AL, 0h
	  	mov [DI], AL
	  	mov AL, 'M'
	  	mov [DI-1], AL
	  	mov AL, 'O'
	  	mov [DI-2], AL
	  	mov AL, 'C'
	  	mov [DI-3], AL
	  	mov AL, '2'
	  	mov [DI-5], AL

	  	mov KEEP_SP, SP
	  	mov KEEP_SS, SS
	  	mov AX, DS
	  	mov ES, AX
	  	mov BX, offset BLOCK
	  	mov DX, offset STR_FILE_PATH
	  	mov AX, 4B00h
	  	int 21h
	  	mov BX, DATA
	  	mov DS, BX
	  	mov SS, KEEP_SS
	  	mov SP, KEEP_SP

	  	jnc COMPLETED
	  	cmp AX, 1
	  	je NOT_COMPL_1
	  	cmp AX, 2
	  	je NOT_COMPL_2
	  	cmp AX, 5
	  	je NOT_COMPL_5
	  	cmp AX, 8
	  	je NOT_COMPL_8
	  	cmp AX, 10
	  	je NOT_COMPL_10
	  	cmp AX, 11
	  	je NOT_COMPL_11
	  NOT_COMPL_1:
	  	mov DX, offset STR_NOT_COMPLETED_CODE_1
	  	call PRINT_STR
	  	jmp LOAD_END
	  NOT_COMPL_2:
	  	mov DX, offset STR_NOT_COMPLETED_CODE_2
	  	call PRINT_STR
	  	jmp LOAD_END
	  NOT_COMPL_5:
	  	mov DX, offset STR_NOT_COMPLETED_CODE_5
	  	call PRINT_STR
	  	jmp LOAD_END
	  NOT_COMPL_8:
	  	mov DX, offset STR_NOT_COMPLETED_CODE_8
	  	call PRINT_STR
	  	jmp LOAD_END
	  NOT_COMPL_10:
	  	mov DX, offset STR_NOT_COMPLETED_CODE_10
	  	call PRINT_STR
	  	jmp LOAD_END
	  NOT_COMPL_11:
	  	mov DX, offset STR_NOT_COMPLETED_CODE_11
	  	call PRINT_STR
	  	jmp LOAD_END

	  COMPLETED:
	  	mov AX, 4D00h
	  	int 21h
	  	cmp AH, 0
	  	je COMPL_0
	  	cmp AH, 1
	  	je COMPL_1
	  	cmp AH, 2
	  	je COMPL_2
	  	cmp AH, 3
	  	je COMPL_3
	  COMPL_0:
	    mov STR_COMPLETED_CODE_0+32, AL
	  	mov DX, offset STR_COMPLETED_CODE_0
	  	call PRINT_STR
	  	jmp LOAD_END
	  COMPL_1:
	  	mov DX, offset STR_COMPLETED_CODE_1
	  	call PRINT_STR
	  	jmp LOAD_END
	  COMPL_2:
	  	mov DX, offset STR_COMPLETED_CODE_2
	  	call PRINT_STR
	  	jmp LOAD_END
	  COMPL_3:
	  	mov DX, offset STR_COMPLETED_CODE_3
	  	call PRINT_STR
	  	jmp LOAD_END

	  LOAD_END:
	  	pop DI
		pop SI
		pop ES
		pop DX
		pop BX
		pop AX
		ret
	LOAD_PROGRAM ENDP

	MAIN PROC
		mov AX, DATA
		mov DS, AX

		call PREPARE_MEM
		cmp IS_PREPARE_SUCCES, 0
		je MAIN_END
		call LOAD_PROGRAM

	  MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
	MAIN ENDP
  LAST_BYTE:
CODE ENDS

END MAIN