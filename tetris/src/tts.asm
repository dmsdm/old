	.model tiny
	.code
	.186
	org 100h
start:
	mov ax,0001h
	int 10h				; text mode 40x25
	call HideCur
	call DrwStakan
	call FillStakan
mainl:	call ChsFig
	mov CurLin,0
	mov CurScr,0
	mov CurCol,19
        call DelLine
move:	call DrwFig
	call ReadKey
	cmp al,1bh			; ESC pressed?
	je exit
	call DelFig
	inc CurLin
	call ChkUnd
	jz move
	dec CurLin
	call DrwFig
	jmp mainl
exit:	call RestoreCur
	mov ax,0003h
	int 10h
	ret

; ### Hide cursor ###
HideCur:
	mov ah,3
	mov bh,0
	int 10h
	mov Pos_cursor,dx
	mov ah,2
	mov bh,0
	mov dx,2500h
	int 10h
	ret

; ### Restore cursor ###
RestoreCur:
	mov ah,2
	mov bh,0
	mov dx,Pos_cursor
	int 10h
	ret

; ### Draw stakan ###
DrwStakan:
	cld
	push 0b800h
	pop es
	mov dx,000eh		; line 0, column 14
	mov ax,1fbah		; draw 'К'
verst:	call GetLinear
	stosw
	add di,20
	stosw
	inc dh
	cmp dh,21
	jbe verst
	call GetLinear
	mov ax,1fc8h		; draw 'Ш'
	stosw
	mov ax,1fcdh		; draw 'Э'
	mov cx,10
	rep stosw
	mov ax,1fbch		; draw 'М'
	stosw
	ret

; ### Fill stakan with ' ' ###
FillStakan:
	cld
	push 0b800h
	pop es
	mov dx,000fh		; line 0, column 15
	mov ax,1f20h
fill:	call GetLinear
	mov cx,10
	rep stosw
	inc dh
	cmp dh,21
	jbe fill
	ret
	
; ### Get linear ###
; INPUT:
;  DH = line
;  DL = column
; OUTPUT:
;  DI = linear address
; ##################
GetLinear:
	push ax
	push bx
	push dx
	shl dl,1			; DL * 2
	mov al,dh
	mov bl,80
	mul bl				; line * 80
	mov di,ax
	xor dh,dh
	add di,dx			; now linear in DI
	pop dx
	pop bx
	pop ax
	ret

; ### Choose figure ###
ChsFig:
	xor ax,ax
	int 1ah
	imul dx,4e35h
	inc dx				; gen random
	shr dx,13			; leave 3 bits
	mov CurFig,dl
	ret

; ### Draw figure ###
DrwFig:
	push cx
	push cs
	pop es
	mov di,offset cFigure
	mov al,CurScr
	mov cx,8
	mov dl,CurFig
	cmp dl,0ffh
	je EFig
	cmp dl,00000001b
	je TFig
	cmp dl,00000010b
	je LFig
	cmp dl,00000011b
	je IFig
	cmp dl,00000100b
	je rFig
	cmp dl,00000101b
	je oFig
	cmp dl,00000110b
	je ZFig
	mov si,offset SFigure
Srsp:	cmp al,0
	je rsp2
	cmp al,32
	je rsp2
	mov CurRsp,1
	jmp FigEx
EFig:	mov si,offset EFigure
	xor ah,ah
	sub si,ax
	jmp FigEx
TFig:	mov si,offset TFigure
	cmp al,16
	je rsp2
	cmp al,48
	je rsp2
	mov CurRsp,1
	jmp FigEx
LFig:	mov si,offset LFigure
	jmp Srsp
IFig:	mov si,offset IFigure
	cmp al,0
	je rsp3
	cmp al,32
	je rsp3
	mov CurRsp,0
	jmp FigEx
rFig:	mov si,offset rFigure
	jmp Srsp
oFig:   mov si,offset oFigure
	mov CurRsp,2
	jmp FigEx
ZFig:   mov si,offset ZFigure
	jmp Srsp
FigEx:	xor ah,ah
	add si,ax
	rep movsw
	call Figure
	pop cx
	ret
rsp2:	mov CurRsp,2
	jmp FigEx
rsp3:	mov CurRsp,3
	jmp FigEx

; ### Draw any figure ###
Figure:
	push cx
	push 0b800h
	pop es
	mov dh,CurLin
	mov dl,CurCol
	mov ah,1fh
	mov si,offset [cFigure+20]
drw:	call GetLinear
	sub si,8
	push dx
	add dh,4
	cmp dh,CurLin
	pop dx
	je Fex
	mov cx,4
lin1:	mov al,byte ptr [si]
	cmp CurFig,0ffh
	je empt
	cmp al,20h
	je skipl
	stosw
	inc si
	loop lin1
	jmp fcyc
empt:	cmp al,20h
	jne skipl
	stosw
	inc si
	loop lin1
	jmp fcyc
skipl:	inc di
	inc di
	inc si
	loop lin1
fcyc:	dec dh
	jns drw
Fex:	pop cx
	ret

; ### Delete Figure ###
DelFig:
	push cs
	pop es
	mov si,offset cFigure
	mov di,offset EFigure
	mov cx,16
invert:	lodsb
	sub al,0bbh
	stosb
	loop invert
	mov bl,CurFig
	push bx
	mov CurFig,0ffh
	call DrwFig
	pop bx
	mov CurFig,bl
	ret

; ### Read key ###
ReadKey:
	mov ah,2ch
	int 21h
	mov bx,dx
	add bx,Speed
	cmp bx,3b5ah		; > 59 sec,90 msec
	ja ReadKey
timer:	mov ah,1
	int 16h
	jnz mrot
	mov ah,2ch
	int 21h
	cmp dx,bx
	jb timer
	ret
mrot:	xor ah,ah
	int 16h
	or al,al
	jz extcode
	cmp al,20h
	je SPACEKey
	cmp al,1bh
	jne timer
	ret
extcode:
	cmp ah,48h		; UP key
	je UPKey
	cmp ah,50h		; DOWN key
	je DOWNKey
	cmp ah,4bh		; LEFT key
	je LEFTKey
	cmp ah,4dh		; RIGHT key
	je RIGHTKey
UPKey:
	push bx
	call Rotate
	pop bx
	jmp timer
DOWNKey:
	ret
LEFTKey:
	call MoveLeft	
	jmp timer
RIGHTKey:
	call MoveRight
	jmp timer
SPACEKey:
	call Pause
	jmp ReadKey

; ### Pause ###
Pause:
	xor ah,ah
	int 16h
;	cmp al,20h
;	jne Pause
;exp:	ret
	ret
	
; ### Rotate Figure ###
; modifies AX
Rotate:
	call DelFig
	mov cl,CurScr
	push cx
	add CurScr,16
	cmp CurScr,48
	jbe rot
	mov CurScr,0
rot:	mov bl,CurLin
	mov bh,CurCol
	push bx
	mov CurLin,28
	mov CurCol,1
	call DrwFig
	call DelFig
	pop bx
	mov CurLin,bl
	mov CurCol,bh
        add CurCol,3
	mov bl,CurRsp
	sub CurCol,bl
	call Chkcol
	pop cx
	jz rot2
	mov CurScr,cl
rot2:	sub Curcol,3
	add CurCol,bl
	call DrwFig
	ret

;џ### Move left ###
MoveLeft:
	call DelFig
	dec CurCol
	call ChkCol
	jz stleft
	inc CurCol
stleft:	call DrwFig
	ret

; ### Move right ###
MoveRight:
	call DelFig
	add CurCol,4
	mov bl,CurRsp
	sub CurCol,bl
	call ChkCol
	jz stright
	dec CurCol
stright:
	sub Curcol,3
	add CurCol,bl
	call DrwFig
	ret

; ### Delete lines ###
DelLine:
	cld
	push 0b800h
	pop es
	mov dx,010fh			; line 1, column 15
	mov ax,1fdbh
comp:	mov cx,11
	call GetLinear
	repz scasw
	jcxz remlin
	inc dh
	cmp dh,21
	jbe comp
	ret
remlin:
	push es
	pop ds
	call GetLinear
	mov si,di
	sub si,80
	mov cx,10
	rep movsw
	dec dh
	cmp dh,0
	ja remlin
	push cs
	pop ds
	call Score
	jmp DelLine

; ### Check column ###
; check if it is possible to move figure
; returns ZF=1 if yes, modifies ax
ChkCol:
	cld
	push 0b800h
	pop es
	mov dh,CurLin
	mov dl,CurCol
chkcel:	call GetLinear
	mov ax,1f20h
	scasw
	ret

; ### Check underline ###
ChkUnd:
	cmp CurLin,3
	jb ChkCol
	mov bl,CurFig
	cmp bl,00000001b
	je TFigi
	cmp bl,00000010b
	je LFigi
	cmp bl,00000011b
	je IFigi
	cmp bl,00000100b
	je rFigi
	cmp bl,00000101b
	je r32scr				; oFigi
	cmp bl,00000110b
	je ZFigi
	cmp CurScr,0
	je S0scr
	cmp CurScr,32
	je S0scr
	call ChkCol
	jz Schk
	ret
Schk:	mov dh,CurLin
	mov dl,CurCol
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz Schk2
	ret
Schk2:  mov dh,CurLin
	mov dl,CurCol
	dec dh
	add dl,2
	jmp chkcel
S0scr:	mov dh,CurLin
	mov dl,CurCol
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz S0chk
	ret
S0chk:	mov dh,CurLin
	mov dl,CurCol
	dec dh
	jmp chkcel
Tfigi:	cmp CurScr,0
	je T0scr
	cmp CurScr,16
	je S0scr
	cmp CurScr,32
	je T32scr
Z0scr:	call ChkCol			; used by Zfigi
	jz Tchk
	ret
Tchk:	mov dh,CurLin
	mov dl,CurCol
	dec dh
	inc dl
	jmp chkcel
T0scr:	mov dh,CurLin
	mov dl,CurCol			; +1
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz Tchk2
	ret
Tchk2:	mov dh,CurLin			; -1
	mov dl,CurCol
	dec dh
	call GetLinear
	mov ax,1f20h
	scasw
	jz Schk2
	ret
T32scr:	call ChkCol
	jz T32Chk
	ret
T32Chk:	mov dh,CurLin
	mov dl,CurCol			; +1
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz T32chk2
	ret
T32chk2:
	mov dh,CurLin
	mov dl,CurCol			; +2
	add dl,2
	jmp chkcel
IFigi:	cmp CurScr,0
	je ChkCol
	cmp CurScr,32
	je ChkCol
	call ChkCol
	jz Ichk
Ichk:	mov dh,CurLin
	mov dl,CurCol			; +1
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz Ichk2
	ret
Ichk2:	mov dh,CurLin
	mov dl,CurCol			; +2
	add dl,2
	call GetLinear
	mov ax,1f20h
	scasw
	jz Ichk3
	ret
Ichk3:	mov dh,CurLin
	mov dl,CurCol			; +3
	add dl,3
	jmp chkcel
rFigi:	cmp CurScr,0
	je r0scr
	cmp CurScr,16
	je r16scr
	cmp CurScr,32
	je r32scr
	jmp T32scr
r0scr:	call ChkCol
	jz r0chk
	ret
r0chk:	mov dh,CurLin			; -2
	mov dl,CurCol			; +1
	sub dh,2
	inc dl
	jmp chkcel
r16scr:	mov dh,CurLin			; -1
	mov dl,CurCol
	dec dh
	call GetLinear
	mov ax,1f20h
	scasw
	jz r16chk
	ret
r16chk:	mov dh,CurLin			; -1
	mov dl,CurCol			; +1
	dec dh
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz r16chk2
	ret
r16chk2:
	mov dh,CurLin
	mov dl,CurCol			; +2
	add dl,2
	jmp chkcel
r32scr:	call ChkCol
	jz r32chk
	ret
r32chk:	mov dh,CurLin
	mov dl,CurCol			; +1
	inc dl
	jmp chkcel
LFigi:	cmp CurScr,0
	je L0scr
	cmp CurScr,16
	je T32scr			; L16scr
	cmp CurScr,32
	je r32scr			; L32scr
	call ChkCol
	jz Lchk
	ret
Lchk:	mov dh,CurLin			; -1
	mov dl,CurCol			; +1
	dec dh
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz Lchk2
	ret
Lchk2:	mov dh,CurLin			; -1
	mov dl,CurCol			; +2
	dec dh
	add dl,2
	jmp chkcel
L0scr:	mov dh,CurLin			; -2
	mov dl,CurCol
	sub dh,2
	call GetLinear
	mov ax,1f20h
	scasw
	jz r32chk
	ret
ZFigi:	cmp CurScr,0
	je Z0scr
	cmp CurScr,32
	je Z0scr
	mov dh,CurLin			; -1
	mov dl,CurCol
	dec dh
	call GetLinear
	mov ax,1f20h
	scasw
	jz Zchk
	ret
Zchk:	mov dh,CurLin
	mov dl,CurCol			; +1
	inc dl
	call GetLinear
	mov ax,1f20h
	scasw
	jz r16chk2
	ret

; ### Display current score ###
Score:
	mov dh,15
	mov dl,32
	call GetLinear
	inc CurScore
	dec Speed
	cmp Speed,15
	jae skpsp
	mov Speed,15
skpsp:	mov ax,CurScore
	mov bx,10
	xor cx,cx
nonzero:
	xor dx,dx
	div bx
	push dx
	inc cx
	cmp ax,0
	jne nonzero
wrdigit:
	pop dx
	add dl,30h
	push ax
	mov al,dl
	mov ah,1fh
	stosw
	pop ax
	loop wrdigit
	ret

; ### Data ###
Pos_cursor dw ?
CurFig db 0
CurLin db 0
CurCol db 19
CurScr db 0
CurRsp db 0
Speed dw 0100h
CurScore dw 0
cFigure  db '    '
         db '    '
         db '    '
         db '    '
EFigure  db '    '
         db '    '
         db '    '
         db '    '
SFigure  db '    '
         db 'л   '
         db 'лл  '
         db ' л  '
         db '    '
         db '    '
         db ' лл '
         db 'лл  '
         db '    '
         db 'л   '
         db 'лл  '
         db ' л  '
	 db '    '
	 db '    '
         db ' лл '
         db 'лл  '
TFigure  db '    '
         db '    '
         db 'ллл '
         db ' л  '
	 db '    '
         db ' л  '
         db 'лл  '
         db ' л  '
	 db '    '
	 db '    '
         db ' л  '
         db 'ллл '
         db '    '
         db 'л   '
         db 'лл  '
         db 'л   '
IFigure  db 'л   '
         db 'л   '
         db 'л   '
         db 'л   '
	 db '    '
	 db '    '
	 db '    '
	 db 'лллл'
	 db 'л   '
         db 'л   '
         db 'л   '
         db 'л   '
	 db '    '
	 db '    '
	 db '    '
	 db 'лллл'
oFigure  db '    '
         db '    '
         db 'лл  '
         db 'лл  '
	 db '    '
         db '    '
         db 'лл  '
         db 'лл  '
	 db '    '
         db '    '
         db 'лл  '
         db 'лл  '
	 db '    '
         db '    '
         db 'лл  '
         db 'лл  '
ZFigure  db '    '
         db ' л  '
         db 'лл  '
         db 'л   '
	 db '    '
	 db '    '
	 db 'лл  '
	 db ' лл '
	 db '    '
         db ' л  '
         db 'лл  '
         db 'л   '
	 db '    '
	 db '    '
	 db 'лл  '
	 db ' лл '
rFigure  db '    '
         db 'лл  '
         db 'л   '
         db 'л   '
	 db '    '
	 db '    '
	 db 'ллл '
	 db '  л '
	 db '    '
         db ' л  '
         db ' л  '
         db 'лл  '
	 db '    '
	 db '    '
	 db 'л   '
	 db 'ллл '
LFigure  db '    '
         db 'лл  '
         db ' л  '
         db ' л  '
	 db '    '
	 db '    '
	 db '  л '
	 db 'ллл '
	 db '    '
	 db 'л   '
	 db 'л   '
	 db 'лл  '
	 db '    '
	 db '    '
	 db 'ллл '
	 db 'л   '

end Start