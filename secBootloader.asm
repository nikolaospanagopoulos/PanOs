org 0x0800

start2:
    ; Set up segment registers
    xor ax, ax                      ; Clear AX register
    mov ds, ax                      ; Set DS to 0x0000
    mov es, ax                      ; Set ES to 0x0000

    ; Set up the stack (downwards)
    mov ss, ax
    mov sp, 0x7C00

	; write success boot 2 message
	mov si, sec_bootloader_success_load_str
	call print_string


	; check for pci buss
	call pci_exists_check
	; check cpuid command exists
	call check_cpuid_availability
	; get cpu information
	call get_cpu_info
    ; Load kernel
    mov bx, 0x1000              ; Segment we want to load the kernel to
    mov es, bx
    mov bx, 0x0000              ; ES:BX = 0x1000:0x0000

set_up_read_disk:
    mov dh, 0x00                ; Head 0
    mov dl, 0x00                ; Drive 0x80 (first hard drive)
    mov ch, 0x00                ; Cylinder 0
    mov cl, 0x05                ; Starting sector to read from (sector 5) (make second bootloader 1536 bytes for extra space)

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

hang:
    jmp hang                    ;Infinite loop


;Prior to using the CPUID instruction, you should also make sure the processor supports it by testing the 'ID' bit (0x200000) in eflags. This bit is modifiable only when the CPUID instruction is supported. For systems that don't support CPUID, changing the 'ID' bit will have no effect.
check_cpuid_availability:
	pushfd                      ;Save EFLAGS to the stack
	pop eax                     ;Load EFLAGS to eax
	mov ecx, eax                ;Copy eax to ecx
	xor eax, 0x00200000         ;Toggle the ID bit in EFLAGS
	push eax                    ;Save modified flags to stack
	popfd                       ;Restore modified EFLAGS
	pushfd                      ;Save EFLAGS to the stack again
	pop eax                     ;Load modified EFLAGS to eax
	xor eax, ecx                ;should be not 0 because they are different
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

;Get cpu information
;When called with EAX = 0, CPUID returns the vendor ID string in EBX, EDX and ECX. Writing these to memory in this order results in a 12-character string.
get_cpu_info:
	mov eax, 0x0
	cpuid                                ;now that we know it exists, we call it
	mov [cpu_vendor_info_str+0],ebx      ;
	mov [cpu_vendor_info_str+4],edx      ;BUILD VENDOR STR
	mov [cpu_vendor_info_str+8],ecx      ;
	mov si, cpu_vendor_msg_str
	call print_string
	mov si, cpu_vendor_info_str
	call print_string
	call get_cpu_stepping
	ret

;Get cpu stepping
get_cpu_stepping:
	mov eax, 1                           ;CPUID function 1: Processor info and features
	cpuid
	and eax, 0x0000000F                  ;mask everything but the stepping
	cmp al, 9
	jle convert_to_digit
	add al, 'A'-10                       ;convert it to ascii (if >=10 add 55)
	jmp store_stepping
convert_to_digit:
	add al, '0'                          ;convert it to ascii (if<10 add 48(0))
store_stepping:
	mov [cpu_stepping_val_str],al
	mov si, cpu_vendor_msg_str
	call print_string
	mov si, cpu_stepping_val_str
	call print_string
	ret




include './printString.asm'
cpu_stepping_msg_str: db 'CPU stepping: ',0
cpu_stepping_val_str: db 1 dup(0), 0xA, 0xD, 0
cpu_vendor_msg_str: db 'CPU vendor: ',0
cpu_vendor_info_str: db 12 dup(0),0xA,0xD,0
cpuid_available_str: db 'CPUID command is available.', 0xA, 0xD,0
cpuid_not_supported_command_string: db 'CPUID command is not supported',0xA,0xD,0
load_error_msg: db 'Error loading kernel!!', 0xA, 0xD, 0
pci_exists_string: db 'Pci exists!',0xA,0xD,0
pci_not_exists_string: db 'Pci doesnt exist!',0xA,0xD,0

pci_exists_check:              ;check pci bus exists
	mov ax, 0xB101             ;0xB101 function
	int 0x1A                   ;BIOS int 0x1A
	jc pci_not_present         ;if carry flag is set, pci doesnt exist
pci_present:
	mov si, pci_exists_string
	call print_string
	jmp pci_checked
pci_not_present:
	mov si, pci_not_exists_string
	call print_string
	jmp hang
pci_checked:
	ret

sec_bootloader_success_load_str: db 'bootloader 2 loaded Successfully',0xA,0xD,0
times 1536-($-$$) db 0  ; Fill the rest of the sector with zeros


