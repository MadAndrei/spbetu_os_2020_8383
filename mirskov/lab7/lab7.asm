DATA SEGMENT
	IS_PREPARE_SUCCES db 1
	IS_FILE_EXIST db 1

	STR_PREPARE_CODE_7 db 'memory control block destroyed', 0DH, 0AH, '$'
	STR_PREPARE_CODE_8 db 'not enough memory to execute function', 0DH, 0AH, '$'
	STR_PREPARE_CODE_9 db 'invalid memory block address', 0DH, 0AH, '$'

	STR_ALLOCATE_CODE_2 db 'file not found', 0DH, 0AH, '$'
	STR_ALLOCATE_CODE_3 db 'path not found', 0DH, 0AH, '$'

	STR_OVERLAY_PATH db 50 dup(0), '$'
	STR_OVERLAY_NAME db 'OVL1.OVL','$'
	
	DTA db 43 dup(0),'$'
	BLOCK dd 0
	KEEP_PSP dw 0
	OVERLAY_ADDRESS dw 0

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

	FREE_MEM PROC
		push AX
		push BX
		push CX

		mov BX, offset LAST_BYTE
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
	FREE_MEM ENDP

	GET_PATH PROC
		push AX
		push DX
		push ES
		push SI
		push DI
		push DS

		mov ES, KEEP_PSP
		mov ES, ES:[2Ch]
		mov SI, 0
		dec SI

	  FIND_ZERO:
	  	inc SI
	  	cmp word ptr ES:[SI], 0 
	  	jne FIND_ZERO

	  	add SI, 4
	  	mov DI, offset STR_OVERLAY_PATH

	  WRITE_PATH:
	  	mov AL, ES:[SI]
	  	mov [DI], AL
	  	inc SI
	  	inc DI
	  	cmp AL, 0
	  	jne WRITE_PATH

	  	sub DI, 9
	  	mov SI, offset STR_OVERLAY_NAME

	  WRITE_NAME:
	  	mov AL, [SI]
	  	mov [DI], AL
	  	inc SI
	  	inc DI
	  	cmp AL, '$'
	  	jne WRITE_NAME

	  	pop DS
	  	pop DI
	  	pop SI
		pop ES
		pop DX
		pop AX
		ret
	GET_PATH ENDP

	ALLOCATE_MEM PROC
		push DX
		push DS
		push AX
		push BX
		push CX
		push SI

		push DS
		mov DX, seg DTA
		mov DS, DX
		mov DX, offset DTA	
		mov AX, 1A00h
		int 21h

		xor CX, CX
		mov DX, seg STR_OVERLAY_PATH
		mov DS, DX
		mov DX, offset STR_OVERLAY_PATH
		mov AX, 4E00h
		int 21h
		pop DS

		jnc ALLOCATE_CODE_GOOD
		mov IS_FILE_EXIST, 0

		cmp AX, 2
		je ALLOCATE_CODE_2

		cmp AX, 3
		je ALLOCATE_CODE_3

	  ALLOCATE_CODE_2:
	  	mov DX, offset STR_ALLOCATE_CODE_2
	  	call PRINT_STR
	  	jmp ALLOCATE_END

	  ALLOCATE_CODE_3:
	  	mov DX, offset STR_ALLOCATE_CODE_3
	  	call PRINT_STR
	  	jmp ALLOCATE_END

	  ALLOCATE_CODE_GOOD:
		mov SI, offset DTA
		mov BX, [SI+1Ah]
		mov CL, 4
		shr BX, CL
		inc BX

		mov AX, 4800h
		int 21h
		mov OVERLAY_ADDRESS, AX

	  ALLOCATE_END:
	  	pop SI
		pop CX
		pop BX
		pop AX
		pop DS
		pop DX
		ret
	ALLOCATE_MEM ENDP

	RUN_OVERLAY PROC
		push AX
		push BX
		push DX
		push ES

		mov BX, DS
		mov ES, BX
		mov BX, offset OVERLAY_ADDRESS
		mov DX, offset STR_OVERLAY_PATH
		mov AX, 4B03h
		int 21h

		mov AX, seg DATA
		mov DS, AX
		mov AX, OVERLAY_ADDRESS
		mov WORD PTR BLOCK+2, AX
		call BLOCK
		mov AX, OVERLAY_ADDRESS
		mov ES, AX
		mov AX, 4900h
		int 21h

		pop ES
		pop DX
		pop BX
		pop AX
		ret
	RUN_OVERLAY ENDP
	
	MAIN PROC
		mov AX, DATA
		mov DS, AX
		mov KEEP_PSP, ES

		call FREE_MEM
		cmp IS_PREPARE_SUCCES, 0
		je MAIN_END

		call GET_PATH
		call ALLOCATE_MEM
		cmp IS_FILE_EXIST, 0
		je NOT_EXIST
		call RUN_OVERLAY

	  NOT_EXIST:
	  	mov IS_FILE_EXIST, 1
		mov byte ptr STR_OVERLAY_NAME+3, 32h
		call GET_PATH
		call ALLOCATE_MEM
		cmp IS_FILE_EXIST, 0
		je MAIN_END
		call RUN_OVERLAY 

	  MAIN_END:
		xor AL, AL
		mov AH, 4Ch
		int 21h
	MAIN ENDP
  LAST_BYTE:
CODE ENDS

END MAIN