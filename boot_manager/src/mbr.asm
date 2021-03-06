    .model tiny
    .code

    org 7c00h

Start:
    jmp _Start

    org 7c0ah

_Start:
    cli     ;deny int
    xor ax,ax
    mov ss,ax
    mov sp,07c00h
    mov si,sp
    push ax
    pop ds
    sti             ;allow int

    mov ax,060h ;move 100h
    push ax         ;bytes from
    pop es          ;0:7c00
    mov di,0    ;to 60:0000
    mov cx,0200h
    cld
    rep movsb

    push es
    pop ds

; CHANGE IT AFTER ASSEMBLING TO  EA2C006000 (JMP 0060:0002C)
; 2C00 - address of read_sec
    jmp dword ptr es:[read_sec]

read_sec:
    mov al,03   ;read 3 sectors
    mov bx,200h ;buffer, where to read
    mov cl,03   ;starting sector 3
    mov dh,0    ;head 0
    mov dl,80h  ;HDD 1
    call Read_Drive
    jnc OK_read

    lea si,error_msg
    call Display_Msg

    mov ah,0    ;wait for input key
    int 16h

    xor ax,ax
    mov es,ax
    jmp dword ptr es:7c00h          ; CHANGE IT AFTER ASSEMBLING TO
                    ; JMP 0000:07C00

OK_read:
    mov bx,0200h    ;jump to code read from sector 3
    call bx

    xor ax,ax
    mov es,ax
    jmp dword ptr es:7c00h      ; CHANGE IT AFTER ASSEMBLING TO
                    ; JMP 0000:07C00

; ######### Read sectors ##########
; INPUT:
;  AL = number of sectors to read
;  BX = Buffer offset
;  CL = start sector
;  DH = head
;  DL = HDD
; OUTPUT:
;  CF=0 - read OK
;  CF=1 - error reading
; #################################

Read_Drive proc

    push di
    mov ah,02   ;read sectors from drive

    mov di,05   ;5 attempts to read

read_atpt:
    push di

    int 13h

    pop di
    jnc out_proc    ;no error - exit

    push ax
    mov ah,0    ;reset disk drives
    int 13h

    pop ax
    dec di
    jnz read_atpt

out_proc:
    pop di
    retn

Read_Drive endp

; ### Display Message ###
; INPUT:
;  SI = offset message
; OUTPUT:
;  Nothing
; #######################

Display_Msg proc

    push ax
    push bx
    push si

    cld     ;DF=0, from left to right

out_sym:
    lodsb
    cmp al,0
    je exit_proc
    push si
    mov bx,07
    mov ah,0eh  ;display AL in teletype mode
    int 10h
    pop si
    jmp out_sym

exit_proc:
    pop si
    pop bx
    pop ax
    retn

Display_Msg endp

; Messages
error_msg db 'Error loading',13,10,0

end Start