org 0x7c00                      ;loaded into memory at 0x0000:0x7c00 (segment 0, address 0x7c00)

;set up segment registers
xor ax, ax                      ;clear ax register
mov ds, ax                      ;set ds to 0x0000
mov es, ax                      ;set es to 0x0000

;set up the stack (downwards)
mov ss, ax
mov sp, 0x7c00

;check if pci exists
call pci_exists_check




	
;set up reading from disk
start:
	mov bx, 0x1000              ;segment we want to load the kernel to
	mov es, bx
	mov bx, 0x0                 ;ES:BX 0x1000:0x00
set_up_read_disk:
	mov dh, 0x0                 ;head 0
	mov dl, 0x0                 ;drive 0
	mov ch, 0x0                 ;cylinder 0
	mov cl, 0x02                ;starting sector to read from. 0x01 is boot , 0x02 is the kernel
read_disk:
	mov ah, 0x02                ;BIOS function to read sectors
	mov al, 0x01                ;number of sectors to read (512 bytes)
	int 0x13                    ;call BIOS to read the sector
	jc load_kernel_err          ;show error message if carry flag is set(carry flag set/ = 1)


;load kernel
load_kernel:
;reset segment registers
	mov ax, 0x1000
    mov ds, ax                  ; data segment
    mov es, ax                  ; extra segment
    mov fs, ax                  ; fs segment
    mov gs, ax                  ; gs segment
    mov ss, ax                  ; stack segment
	mov sp, 0xFFFE              ; TODO: rethink this. set stack pointer to the top of the stack
    jmp 0x1000:0x0              ; never return from this!

load_kernel_err:
	mov si, load_error_msg
	call print_string

include './printString.asm'
load_error_msg: db 'Error loading kernel!!',0xA,0xD,0

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
pci_checked:
	ret


;Print a char for testing
;mov al, 'A'
;mov ah, 0eh
;int 0x10

times 510 - ($ - $$) db 0        ;pad everything with 0s

dw 0xAA55                        ;The (legacy) BIOS checks bootable devices for a boot signature, a so called magic number. The boot signature is in a boot sector (sector number 0) and it contains the byte sequence 0x55, 0xAA at byte offsets 510 and 511 respectively. 
