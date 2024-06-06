kernel:

	mov si, kernelStatusString
	call print_string
	mov si, welcomeString
	call print_string
	jmp $








include './printString.asm'

welcomeString: db 'Welcome to PanOs', 0xA, 0xD, 0
kernelStatusString: db 'Kernel loaded Successfully', 0xA, 0xD, 0
