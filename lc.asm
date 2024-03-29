SYS_READ:		equ		0
SYS_WRITE:		equ		1
SYS_EXIT:		equ		60

STDIN_FILENO:		equ		0
STDOUT_FILENO:		equ		1
STDERR_FILENO:		equ		2

EXIT_SUCCESS:		equ		0
EXIT_FAILURE:		equ		1

			section		.text
			global		_start

_start:
			xor		ebp, ebp
			sub		rsp, read_buf_size

read_next_block:
			xor		eax, eax 		; SYS_READ
			xor		edi, edi		; STDIN_FILENO
			mov		rsi, rsp
			mov		edx, read_buf_size
			syscall
			; rax == 0                   end of file
			; rax in [1; read_buf_size]  success
			; rax in [-4095; -1]         error
			; rax in [read_buf_size + 1; -4096]  "impossible"
			
			test		rax, rax
			jz		eof
			js		read_error

			lea		rdi, [rsp + rax]
			mov		rsi, rsp

next_char:
			cmp		byte [rsi], 10
			jne		dont_increment
			inc		rbp
dont_increment:
			inc		rsi
			cmp		rsi, rdi
			jne		next_char

			jmp		read_next_block

eof:
			add		rsp, read_buf_size

			lea		rsi, [rsp - 1]
			mov		byte [rsi], 10
			mov		rax, rbp
			mov		rbx, 10

next_digit:
			xor		edx, edx
			div		rbx
			add		edx, '0'
			dec		rsi
			mov		[rsi], dl
			test		rax, rax
			jnz		next_digit

			mov		eax, SYS_WRITE
			mov		edi, STDOUT_FILENO
			mov		rdx, rsp
			sub		rdx, rsi
			syscall

			mov		eax, SYS_EXIT
			xor		edi, edi		; EXIT_SUCCESS
			syscall

read_error:
			mov		eax, SYS_WRITE
			mov		edi, STDERR_FILENO
			mov		rsi, read_error_msg
			mov		edx, read_error_msg_size
			syscall

			mov		eax, SYS_EXIT
			mov		edi, EXIT_FAILURE
			syscall

			section		.rodata
read_error_msg:		db		"read failed", 10
read_error_msg_size:	equ		$ - read_error_msg

read_buf_size:		equ		8192
