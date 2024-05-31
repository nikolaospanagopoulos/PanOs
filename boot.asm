org 0x7c00                      ;loaded into memory at 0x0000:0x7c00 (segment 0, address 0x7c00)

	
;set up reading from disk
start:
	mov bx, 0x1000
	mov es, bx
	mov bx, 0x0                 ;ES:BX 0x1000:0x00
set_up_read_disk:
	mov dh, 0x0                 ;head 0
	mov dl, 0x0                 ;drive 0
	mov ch, 0x0                 ;cylinder 0
	mov cl, 0x02                ;starting sector to read from. 0x01 is boot , 0x02 is the kernel
read_disk:
	mov ah, 0x02
	mov al, 0x01
	int 0x13
	jc read_disk                ;retry if disk read error (carry flag set/ = 1)


;load kernel
load_kernel:
;reset segment registers
	mov ax, 0x1000
    mov ds, ax                  ; data segment
    mov es, ax                  ; extra segment
    mov fs, ax                  ; ""
    mov gs, ax                  ; ""
    mov ss, ax                  ; stack segment

    jmp 0x1000:0x0              ; never return from this!









;Print a char for testing
;mov al, 'A'
;mov ah, 0eh
;int 0x10

times 510 - ($ - $$) db 0        ;pad everything with 0s

dw 0xAA55                        ;The (legacy) BIOS checks bootable devices for a boot signature, a so called magic number. The boot signature is in a boot sector (sector number 0) and it contains the byte sequence 0x55, 0xAA at byte offsets 510 and 511 respectively. 
