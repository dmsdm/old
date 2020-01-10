title   install (com)
    .model tiny
    .386
    .code

    org 100h

main proc
    lea dx,bckmsg
    call Out_str
    call Ask_yn
    jnc nobck
    call Backup_mbr
nobck:
        lea dx,instmsg
    call Out_str
    call Ask_yn
    jc instbm
    ret
instbm:
    call Inst_bm
    jnc exit
    lea dx,errimsg
    call Out_str
exit:
    ret
main endp

; ### Display string using DOS ###
; INPUT:
;   dx - message offset ( msg must be finished with '$' )
; OUTPUT:
;   nothing
; ################################
Out_str proc
    pusha
    mov ah,9
    int 21h
    popa
    ret
Out_str endp

; ### handle y/n question ###
; INPUT:
;   nothing
; OUTPUT:
;   CF=1 - yes
;   CF=0 - no
; ###########################
Ask_yn proc
    pusha
    clc
    xor ah,ah
    int 16h
    cmp al,'Y'
    je yes
    cmp al,'y'
    je yes
    clc
    popa
    ret
yes:
    stc
    popa
    ret
Ask_yn endp

; ### Backup current MBR ###
; INPUT:
;   nothing
; OUTPUT:
;   nothing
; ##########################
Backup_mbr proc
    pusha
    mov al,1
    lea bx,buf
    mov cx,1
    mov dh,0
    mov dl,80h
    call Read_drive
    jnc save
    lea dx,readerr
    call Out_str
    popa
    int 20h
save:
    lea dx,mbrfile
    call Save_file
    jnc save_ok
    lea dx,wrferr
    call Out_str
    popa
    int 20h
save_ok:
    lea dx,mbrsmsg
    call Out_str
    popa
    ret
Backup_mbr endp

; ### Reading sectors procedure ###
; INPUT:
;  AL = number of sectors to read
;  BX = Buffer offset
;  CH = cylinder
;  CL = cyl (6-7) start sector (0-5)
;  DH = head
;  DL = HDD
; OUTPUT:
;  CF=0 - read OK
;  CF=1 - error reading
; #################################
Read_drive proc
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
    ret
Read_drive endp

; ### Save file 512b from buf to disk ###
; INPUT:
;   dx - ASCIZ-string with file name
; OUTPUT:
;   cf=1 - error writing file
;   cf=0 - writing file ok
; #######################################
Save_file proc
    pusha
    mov ah,3ch  ; create file  (5bh - create new file)
    xor cx,cx   ; No attributes
    int 21h
    jc errs
    mov handle,ax
    mov ah,40h
    mov bx,handle
    mov cx,200h
    lea dx,buf
    int 21h
    jc errs
    mov ah,3eh
    mov bx,handle
    int 21h
errs:
    popa
    ret
Save_file endp

; ### Writing bootmanager to MBR ###
; INPUT:
;   nothing
; OUTPUT:
;   nothing
; ##########################
Inst_bm proc
    pusha
    mov al,1
    lea bx,buf
    mov cx,1
    mov dh,0
    mov dl,80h
    call Read_drive
    jc erri
    lea dx,bmfile
    mov cx,157      ; bytes read to buf
    call Read_file
    jc erri
    mov al,1
    lea bx,buf
    mov cx,1
    mov dh,0
    mov dl,80h
    call Write_drive
    jc erri
    lea dx,mnufile
    mov cx,1192     ; bytes read to buf
    call Read_file
    jc erri
    call name_part      ; Input names for partitions
    mov al,3        ; write 3 sectors
    lea bx,buf
    mov cx,3        ; starting sector 3
    mov dh,0        ; head
    mov dl,80h
    call Write_drive
    jc erri
    lea dx,sucinst
    call Out_str
erri:
    popa
    ret
Inst_bm endp

; ### Read file from disk ###
; INPUT:
;   dx - ASCIZ-string with file name
; OUTPUT:
;   cf=1 - error writing file
;   cf=0 - writing file ok
; #########################
Read_file proc
    pusha
    push cx
    mov ax,3d00h
    xor cx,cx   ; No attributes
    int 21h
    jc errr
    mov handle,ax
    mov ah,3fh
    mov bx,handle
    pop cx
    lea dx,buf
    int 21h
    jc errr
    mov ah,3eh
    mov bx,handle
    int 21h
errr:
    popa
    ret
Read_file endp

; ### Writing sectors procedure ###
; INPUT:
;  AL = number of sectors to write
;  BX = Buffer offset
;  CH = cylinder
;  CL = cyl (6-7) start sector (0-5)
;  DH = head
;  DL = HDD
; OUTPUT:
;  CF=0 - write OK
;  CF=1 - error writing
; #################################
Write_drive proc
    push di
    mov ah,03   ;write sectors to drive
    mov di,05   ;5 attempts to write
write_atpt:
    push di
    int 13h
    pop di
    jnc out_write   ;no error - exit
    push ax
    mov ah,0    ;reset disk drives
    int 13h
    pop ax
    dec di
    jnz write_atpt
out_write:
    pop di
    ret
Write_drive endp

; ### Enter names for partitions ###
; INPUT:
;   nothing
; IUTPUT:
;   nothing
; ##################################
name_part proc
    pusha
;part1
    lea dx,part1
    call out_str
    lea dx,prtname
    mov ah,0ah
    int 21h
    mov bl,[prtname+1]      ;string length
    xor bh,bh
    add bx,2
    mov prtname[bx],20h
    mov cx,16
    lea si,[prtname+2]
    lea di,[buf+42ch]
    rep movsb
    mov al,20h
    mov cx,16
    lea di,[prtname+2]
    rep stosb
;part2
    lea dx,part2
    call out_str
    lea dx,prtname
    mov ah,0ah
    int 21h
    lea dx,prtname
    mov bl,[prtname+1]      ;string length
    xor bh,bh
    add bx,2
    mov prtname[bx],20h
    mov cx,16
    lea si,[prtname+2]
    lea di,[buf+440h]
    rep movsb
    mov al,20h
    mov cx,16
    lea di,[prtname+2]
    rep stosb
;part3
    lea dx,part3
    call out_str
    lea dx,prtname
    mov ah,0ah
    int 21h
    lea dx,prtname
    mov bl,[prtname+1]      ;string length
    xor bh,bh
    add bx,2
    mov prtname[bx],20h
    mov cx,16
    lea si,[prtname+2]
    lea di,[buf+454h]
    rep movsb
    mov al,20h
    mov cx,16
    lea di,[prtname+2]
    rep stosb
;part4
    lea dx,part4
    call out_str
    lea dx,prtname
    mov ah,0ah
    int 21h
    lea dx,prtname
    mov bl,[prtname+1]      ;string length
    xor bh,bh
    add bx,2
    mov prtname[bx],20h
    mov cx,16
    lea si,[prtname+2]
    lea di,[buf+468h]
    rep movsb
;default partition
defp:   lea dx,defpart
    call out_str
    xor ah,ah
    int 16h
    cmp al,'1'
    je endn
    cmp al,'2'
    je n2
    cmp al,'3'
    je n3
    cmp al,'4'
    je n4
    jmp defp
n2: mov [buf+0fh],0bh
    jmp endn
n3: mov [buf+0fh],0ch
    jmp endn
n4: mov [buf+0fh],0dh
endn:   popa
    ret
name_part endp


handle  dw  0ffffh
bckmsg  db  0dh,0ah,'Do you wish to backup your current MBR [n]?','$'
readerr db  0dh,0ah,'Error reading sector','$'
wrferr  db  0dh,0ah,'Error writing file','$'
errimsg db  0dh,0ah,'Error writing bootmanager','$'
mbrfile db  'a:\mbrbck.bin',0
bmfile  db  'a:\bmmbr.bin',0
mnufile db  'a:\selmu.bin',0
mbrsmsg db  0dh,0ah,'MBR succesfully saved to a:\mbrbck.bin','$'
sucinst db  0dh,0ah,'Simple bootmanager succesfully installed','$'
instmsg db  0dh,0ah,'Do you wish to install simple bootmanager [n]?','$'
part1   db  0dh,0ah,'Input name for the first partition[15 symbols]: ','$'
part2   db  0dh,0ah,'Input name for the second partition[15 symbols]: ','$'
part3   db  0dh,0ah,'Input name for the third partition[15 symbols]: ','$'
part4   db  0dh,0ah,'Input name for the forth partition[15 symbols]: ','$'
defpart db  0dh,0ah,'Input number for the default partition[1-4]: ','$'
prtname db  16,?,16 dup (20h)
buf db  2048 dup (?)

end main
