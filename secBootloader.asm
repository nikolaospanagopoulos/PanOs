org 0x0800

start2:
    ; Set up segment registers
    xor ax, ax                      ; Clear AX register
    mov ds, ax                      ; Set DS to 0x0000
    mov es, ax                      ; Set ES to 0x0000

    ; Set up the stack (downwards)
    mov ss, ax
    mov sp, 0x7C00


	; check for pci buss
	call pci_exists_check
    ; Load kernel
    mov bx, 0x1000              ; Segment we want to load the kernel to
    mov es, bx
    mov bx, 0x0000              ; ES:BX = 0x1000:0x0000

set_up_read_disk:
    mov dh, 0x00                ; Head 0
    mov dl, 0x00                ; Drive 0x80 (first hard drive)
    mov ch, 0x00                ; Cylinder 0
    mov cl, 0x04                ; Starting sector to read from (sector 4) (make second bootloader 1024 bytes for extra space)

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

include './printString.asm'

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


times 1024-($-$$) db 0  ; Fill the rest of the sector with zeros

