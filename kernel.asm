
mov si, testString
call print_string
jmp $








include './printString.asm'

testString: db 'Welcome to PanOs', 0xA, 0xD, 0
