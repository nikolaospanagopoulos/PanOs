org 0x7c00                      ;loaded into memory at 0x0000:0x7c00 (segment 0, address 0x7c00)
;FIRST STAGE BOOTLOADER THAT WILL LOAD THE SECOND STAGE BOOTLOADER

;set up segment registers
xor ax, ax                      ;clear ax register
mov ds, ax                      ;set ds to 0x0000
mov es, ax                      ;set es to 0x0000

;set up the stack (downwards)
mov ss, ax
mov sp, 0x7c00


mov ax, 0x0000              ;
mov es, ax                  ;es:bx 0x0000:0x0800
mov bx, 0x0800              ;
mov ah, 0x02                ;BIOS function to read sectors
mov al, 0x04                ;number of sectors to read (512 bytes each sector)
mov dh, 0x0                 ;head 0
mov dl, 0x0                 ;drive 0
mov ch, 0x0                 ;cylinder 0
mov cl, 0x02                ;starting sector to read from. 0x01 is boot 1, 0x2 is boot2
int 0x13                    ;call BIOS to read the sector
jc load_sector_error        ;show error message if carry flag is set(carry flag set/ = 1)
jmp 0x0000:0x0800           ;never return from this!




load_sector_error:
	mov si, load_sector_error_str
	call print_string
	hlt

include './printString.asm'


load_sector_error_str: db 'Couldnt load disk sector!',0xA,0xD,0
times 510 - ($ - $$) db 0        ;pad everything with 0s

dw 0xAA55                        ;The (legacy) BIOS checks bootable devices for a boot signature, a so called magic number. The boot signature is in a boot sector (sector number 0) and it contains the byte sequence 0x55, 0xAA at byte offsets 510 and 511 respectively. 
