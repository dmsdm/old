title	selmu (com)
	.model tiny
	.386
	.code

	org 200h

a10main proc
a20:	call q10clear		; clear screen
	mov row,botrow+4	; set row
	call b10menu		; display menu
	mov row,toprow+1	; set current position
	mov attrib,17h		; switch to inverse display mode
	call d10disply		; enlight current row in menu
	call c10input		; make selection from menu
	jmp a20			; 
	ret
a10main endp

; ### Display menu and invitaion ###
b10menu proc
	pusha			; save registers
	mov bx,0020h		; page and attributes
	lea bp,shadow		; "shadow" symbols
	mov dh,toprow+1		; upper shadow row
b20:	mov dl,lefcol+1		; left shadow column
	mov ax,1301h
	mov cx,20		; number of symbols
	int 10h
	inc dh			; next row
	cmp dh,botrow+2		; all rows displayed?
	jne b20			;   No - repeat
	mov attrib,71h		; blue symbols, white background
	movzx bx,attrib		; page and attributes
	lea bp,menu		; menu string
	mov dh,toprow		; row
b30:	mov dl,lefcol		; column
	mov ax,1301h
	mov cx,20
	int 10h
	add bp,20		; next menu string
	inc dh			; next column
	cmp dh,botrow+1		; all strings displayed?
	jne b30			;   No - repeat
	popa			; restore registers
	ret
b10menu endp

; ### Process keys to navigate menu and exit ###
c10input proc
	pusha
	mov ah,02
	int 1ah
	jc c20
	mov bh,dh
	push bx
	mov dh,01		; line number
	mov dl,01		; left column
	mov ax,1300h
	mov cx,1		; number of symbols
	lea bp,sec
	mov bx,21h
	int 10h
	pop bx
timer:
	mov ah,02
	int 1ah
	jc c20
	cmp bh,dh
	je t1
	mov bh,dh
	dec sec
	cmp sec,30h
	jb c99
	push bx
	mov dh,01		; line number
	mov dl,01		; left column
	mov ax,1300h
	mov cx,1		; number of symbols
	lea bp,sec
	mov bx,21h
	int 10h
	pop bx
t1:
	mov ah,01h
	int 16h
	jnz c20
	jmp timer
c20:
	mov ah,10h		; request one symbol from keyboard
	int 16h
	cmp ah,50h		; DOWN key?
	je c30
	cmp ah,48h		; UP key?
	je c40
	cmp al,0dh		; ENTER key?
	je c99
	jmp c20			; repeat
c30:
	mov attrib,71h		; white symbols on blue background
	call d10disply		; set previously selected string to common mode
	inc row			; next string
	cmp row,botrow-1	; lower lowest string?
	jbe c50			;   No - execute
	mov row,toprow+1	;   Yes - up
	jmp c50
c40:
	mov attrib,71h		; blue symbols on white background
	call d10disply		; set previously selected string to common mode
	dec row
	cmp row,toprow+1	; Upper string?
	jae c50			;   No - execute
	mov row,botrow-1	;   Yes - reset
c50:
	mov attrib,17h		; white symbols on blue background
	call d10disply		; set current string to inverse mode
	jmp c20
c99:	call readLBA
	jnc ok_read
        mov dh,20		; line number
	mov dl,lefcol+1		; left shadow column
	mov ax,1300h
	mov cx,10		; number of symbols
	lea bp,err_msg
	mov bx,71h
	int 10h
	jmp c20
ok_read:	
	mov ax,0600h
	mov cx,0
	xor bh,bh
	mov dx,184fh
	int 10h
        mov ah,02h
	mov bx,0007h
	mov dx,0
	int 10h
	popa
	jmp dword ptr es:7c00h	; AFTER ASSMBLNG CHNG TO JMP 0000:07C00
	ret
c10input endp

; ### Light selected string and set previous to common mode ###
d10disply proc
	pusha
	movzx ax,row		; what string to change
	sub ax,toprow
	imul ax,20		; multiply with string length
	lea si,menu+1		;   to get needed string
	add si,ax
	mov ax,1300h		; request output
	movzx bx,attrib		; page and attributes
	mov bp,si		; string
	mov cx,18		; string length
	mov dh,row		; row
	mov dl,lefcol+1		; column
	int 10h
	popa
	ret
d10disply endp

; ### Clear screen ###
q10clear proc
	pusha
	mov ax,0600h
	mov bh,21h		; blue symbols, brown background
	mov cx,0000		; whole screen
	mov dx,184fh
	int 10h
	popa
	ret
q10clear endp

; ### Read selected partition in LBA mode ###
readLBA proc
	pusha
	push es
	mov ax,060h
	push ax
	pop es
	cmp row,10
	je r1st
	cmp row,11
	je r2nd
	cmp row,12
	je r3rd
	mov di,1eeh
	jmp read
r1st:   mov di,1beh
	jmp read
r2nd:	mov di,1ceh
	jmp read
r3rd:	mov di,1deh
read:	mov eax,es:[di+8]
	mov dap.st_sec,eax
	mov cx,05		; Five read attempts
rread:	mov ah,42h		; Read sector in LBA mode
	mov dl,80h		; Read from first disk
	lea si,dap		; Disk Address packet offset
	push cx
	int 13h
	pop cx
	jnc read_ok
	push ax
	mov ah,0		; Reset disk drives
	int 13h
	pop ax
	dec cx
	jnz rread
	stc
read_ok:
	pop es
	popa
	ret
readLBA endp

sec	db	39h		; delay seconds

	org 600h

toprow	equ	09		; upper string in menu
botrow	equ	14		; lower string
lefcol	equ	26		; left column
attrib	db	?		; screen attributes
row	db	00		; screen row
shadow	db	20 dup (0dbh)	; "shadow" symbols
menu	db	0c9h, 18 dup (0cdh), 0bbh
	db	0bah, ' First partition  ', 0bah
	db	0bah, ' Second partition ', 0bah
	db	0bah, ' Third partition  ', 0bah
	db	0bah, ' Forth partition  ', 0bah
	db	0c8h, 18 dup (0cdh), 0bch
err_msg db	'Read Error'
daplist	struc
d_size	db	10h
d_rsrv1	db	00h
num_sec	db	01h
d_rsrv2	db	00h
buf_seg	dw	7c00h
buf_off	dw	00h
st_sec	dd	0
	dd	0
daplist	ends
dap	daplist <>

end a10main
	