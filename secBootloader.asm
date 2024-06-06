org 0x0800

CODE_SEG equ gdt_code - gdt
DATA_SEG equ gdt_data_segment - gdt

start2:
    ; Set up segment registers
    xor ax, ax                      ; Clear AX register
    mov ds, ax                      ; Set DS to 0x0000
    mov es, ax                      ; Set ES to 0x0000

    ; Set up the stack (downwards)
    mov ss, ax
    mov sp, 0x7C00

    ; Write success boot 2 message
	mov si, sec_bootloader_success_load_str
	call print_string

    ; Check for PCI bus
    call pci_exists_check
    ; Check CPUID command exists
    call check_cpuid_availability
    ; Get CPU information
    call get_cpu_info
    ; Check if MSR is supported
    call msr_is_supported_check
	; Enable A20 line
	call enable_a20_line

	 ; Enter Protected Mode
step2:
	cli
    mov ax, 0x00                ; Data segment selector
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00             ; Stack pointer
	sti
.load_protected:
	cli
	lgdt[gdt_descriptor]

   mov eax, cr0
   or eax, 0x1
   mov cr0, eax
   jmp CODE_SEG:load32



    ; Your 32-bit code starts here
    ; ...

hang:
    jmp hang                    ; Infinite loop to prevent falling off


    ; Load kernel
    mov bx, 0x1000              ; Segment we want to load the kernel to
    mov es, bx
    mov bx, 0x0000              ; ES:BX = 0x1000:0x0000

set_up_read_disk:
    mov dh, 0x00                ; Head 0
    mov dl, 0x00                ; Drive 0x80 (first hard drive)
    mov ch, 0x00                ; Cylinder 0
    mov cl, 0x06                ; Starting sector to read from (sector 5)

read_disk:
    mov ah, 0x02                ; BIOS function to read sectors
    mov al, 0x02                ; Number of sectors to read (2 sectors = 1024 bytes)
    int 0x13                    ; Call BIOS to read the sectors
    jc load_kernel_err          ; Show error message if carry flag is set

    ; Successfully loaded kernel, now jump to it
load_kernel:
    ; Reset segment registers
    mov ax, 0x1000
    mov ds, ax                  ; Data segment
    mov es, ax                  ; Extra segment
    mov fs, ax                  ; FS segment
    mov gs, ax                  ; GS segment
    mov ss, ax                  ; Stack segment
    mov sp, 0xFFFE              ; Set stack pointer to the top of the segment
    jmp 0x1000:0x0000           ; Jump to the kernel

load_kernel_err:
    mov si, load_error_msg
    call print_string
    jmp hang                    ; Infinite loop to prevent further execution

check_cpuid_availability:
    pushf                      ; Save EFLAGS to the stack
    pop ax                     ; Load EFLAGS to AX
    mov cx, ax                 ; Copy AX to CX
    xor ax, 0x2000             ; Toggle the ID bit in EFLAGS
    push ax                    ; Save modified flags to stack
    popf                       ; Restore modified EFLAGS
    pushf                      ; Save EFLAGS to the stack again
    pop ax                     ; Load modified EFLAGS to AX
    xor ax, cx                 ; Compare original and modified EFLAGS
    jz cpuid_command_not_present

cpuid_present:
    mov si, cpuid_available_str
    call print_string
    jmp cpuid_command_checked

cpuid_command_not_present:
    mov si, cpuid_not_supported_command_string
    call print_string

cpuid_command_checked:
    ret

get_cpu_info:
    mov ax, 0x0
    cpuid                                ; Now that we know it exists, we call it
    mov [cpu_vendor_info_str+0], ebx      ; Store vendor string part 1
    mov [cpu_vendor_info_str+4], edx      ; Store vendor string part 2
    mov [cpu_vendor_info_str+8], ecx      ; Store vendor string part 3
    mov si, cpu_vendor_msg_str
    call print_string
    mov si, cpu_vendor_info_str
    call print_string
	call get_cpu_stepping
    ret

pci_exists_check:
	pusha
    mov ax, 0xB101             ; 0xB101 function
    int 0x1A                   ; BIOS int 0x1A
    jc pci_not_present         ; If carry flag is set, PCI doesn't exist

pci_present:
    mov si, pci_exists_string
    call print_string
    jmp pci_checked

pci_not_present:
    mov si, pci_not_exists_string
    call print_string
    jmp hang

pci_checked:
	popa
    ret

msr_is_supported_check:
    mov ax, 1
    cpuid
    test edx, 0x0020           ; Check if bit 5 is set
    jz msr_not_supported       ; MSR is not supported

msr_is_supported:
    mov si, msr_supported_str
    call print_string
    jmp end_check

msr_not_supported:
    mov si, msr_not_supported_str
    call print_string

end_check:
    ret

;Get cpu stepping
get_cpu_stepping:
	mov ax, 1                            ;CPUID function 1: Processor info and features
	cpuid
	and ax, 0x000F                       ;mask everything but the stepping
	cmp al, 9
	jle convert_to_digit
	add al, 'A'-10                       ;convert it to ascii (if >=10 add 55)
	jmp store_stepping
convert_to_digit:
	add al, '0'                          ;convert it to ascii (if<10 add 48(0))
store_stepping:
	mov [cpu_stepping_val_str],al
	mov si, cpu_stepping_msg_str
	call print_string
	mov si, cpu_stepping_val_str
	call print_string
	ret

;Enable A20 line
enable_a20_line:
	in al, 0x92                          ;read current value from port 0x92
    or al, 2                             ;set the second bit to enable A20 line
    out 0x92, al                         ;write the new value back to 0x92 port
	mov si, a20_line_enabled_str
	call print_string
	ret

gdt:
	;null descriptor
	dd 0x0
	dd 0x0
gdt_code:
	;code sergment descriptor
    dw 0xFFFF                   ; Limit (16 bits)
    dw 0x0000                   ; Base (low 16 bits)
    db 0x00                     ; Base (next 8 bits)
    db 10011010b                ; Access byte
    db 11001111b                ; Flags (Limit high 4 bits and granularity)
    db 0x00                     ; Base (high 8 bits)
gdt_data_segment:
    ; Data Segment Descriptor
    dw 0xFFFF                   ; Limit (16 bits)
    dw 0x0000                   ; Base (low 16 bits)
    db 0x00                     ; Base (next 8 bits)
    db 10010010b                ; Access byte
    db 11001111b                ; Flags (Limit high 4 bits and granularity)
    db 0x00                     ; Base (high 8 bits)
gdt_end:

gdt_descriptor:
	dw gdt_end - gdt - 1       ;size of gdt
	dd gdt                     ;address of gdt








include './printString.asm'

cpu_stepping_msg_str: db 'CPU stepping: ', 0
cpu_stepping_val_str: db 1 dup(0), 0xA, 0xD, 0
cpu_vendor_msg_str: db 'CPU vendor: ', 0
cpu_vendor_info_str: db 12 dup(0), 0xA, 0xD, 0
cpuid_available_str: db 'CPUID command is available.', 0xA, 0xD, 0
cpuid_not_supported_command_string: db 'CPUID command is not supported', 0xA, 0xD, 0
load_error_msg: db 'Error loading kernel!!', 0xA, 0xD, 0
pci_exists_string: db 'PCI exists', 0xA, 0xD, 0
pci_not_exists_string: db 'PCI doesnt exist!', 0xA, 0xD, 0
msr_supported_str: db 'MSR is supported', 0xA, 0xD, 0
msr_not_supported_str: db 'MSR is not supported', 0xA, 0xD, 0
sec_bootloader_success_load_str: db 'Second Bootloader Loaded Successfully', 0xA, 0xD, 0
a20_line_enabled_str: db 'A20 line enabled successfully', 0xA , 0xD , 0

use32
load32:
	mov ax, DATA_SEG
    mov ds, ax
    mov es, ax

    ; Print the string
    mov esi, xazo              ; Source index pointing to string
    mov edi, 0xB8000           ; Destination index pointing to VGA memory
    call pm_print_string

    ; Hang
    jmp $


pm_print_string:
    pusha
    mov ah, 0x0F            ; Attribute byte: white text on black background
.print_loop:
    lodsb                   ; Load next byte from string into AL
    cmp al, 0
    je .done                ; If null terminator, end of string
    mov [es:edi], ax        ; Write character and attribute to video memory
    add edi, 2              ; Move to next character position
    jmp .print_loop
.done:
    popa
    ret


xazo: db 'hello',0xA,0xD,0




times 2048-($-$$) db 0  ; Fill the rest of the sector with zeros

