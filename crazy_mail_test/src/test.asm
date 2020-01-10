.486
.model Flat, Stdcall
option Casemap :None   ; case sensitive

include Windows.inc
include kernel32.inc
includelib kernel32.lib
include user32.inc
includelib user32.lib
include wsock32.inc
includelib wsock32.lib
include comdlg32.inc
includelib comdlg32.lib
include shell32.inc
includelib shell32.lib

DlgProc		PROTO	:HWND,:UINT,:WPARAM,:LPARAM
ConnectHost	PROTO	:DWORD,:DWORD
Receive		PROTO	:DWORD
HandShake	PROTO	:DWORD
SendMsg		PROTO	:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SendAtt		PROTO	:DWORD,:DWORD
SendQuit		PROTO	:DWORD
CheckHost	PROTO	:HWND
LoopMsg		PROTO	:HWND
BrowseFile	PROTO	:HWND
FileEnc      	PROTO
FileOpen		PROTO
GetEmail		PROTO
b64_encode	PROTO 	:DWORD, :DWORD, :DWORD
InitData		PROTO	:HWND
WriteToLog	PROTO	:DWORD
LogError		PROTO	:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
LogEvent		PROTO	:DWORD,:DWORD,:DWORD,:DWORD
; menus and buttons handlers
MnuAddToSubj PROTO	:HWND
MnuAddDateTime PROTO :HWND
MnuLog		PROTO	:HWND,:BYTE,:UINT,:UINT,:UINT
MnuRcptFF	PROTO	:HWND
BtnSend		PROTO	:HWND
BtnCycle		PROTO	:HWND
BtnBrowse	PROTO	:HWND,:DWORD,:DWORD,:UINT,:DWORD

.const
TestDialog	equ 100
Send		equ 201
Check		equ 1014
Cycle		equ 1016
FromEdit		equ 1003
ToEdit		equ 1004
SubjEdit		equ 1005
BodyEdit		equ 1011
ServerEdit	equ 1013
Exit			equ 2002
fileatt1 		equ 1017
fileatt2 		equ 1018
fileatt3 		equ 1019
Browse1 		equ 1021
Browse2		equ 1022
Browse3		equ 1023
file_name1	equ 1024
file_name2	equ 1025
file_name3	equ 1026
IP_check		equ 1040
StatusBar 	equ 1027
MainMenu 	equ 1000
AddtoSubj	equ 2004
ThreadsNum 	equ 1028
Spin			equ 1032
DelayVal		equ 1035
SpinDelay	equ 1036
CountChk		equ 1039
CountVal		equ 1037
Load		equ 2007
Save			equ 2008
AddDateTime	equ 2009
RcptFF		equ 2010
Nologs		equ 2012
Logerrors		equ 2013
Fulllog		equ 2014
TRAY		equ 0
WM_SHELLNOTIFY equ WM_USER+5
testicon		equ 3000

.data
;ini
lpAppName 	db "main",0
lpFrom 		db "from",0
lpTo			db "to",0
lpSubj		db "subj",0
lpBody		db "body",0
lpServer		db "server",0
IniFileName	db ".\\crazy.ini",0

;message
helo 			db "helo server", 13, 10, 0
MFrom		db "mail from:<%s>",13,10,0
FromText		db 128 dup(?)
RTo			db "rcpt to:<%s>",13,10,0
ToText		db 128 dup(?)
SData 		db "data",13,10,0
Subj 		db "subject: =?windows-1251?Q?%s?=",13,10,0
SubjNum 		db "subject: =?windows-1251?Q?%s %s %s %d?=",13,10,0
SubjDate 		db "subject: =?windows-1251?Q?%s %s %s?=",13,10,0
SubjText		db 128 dup(?)
To 			db "to: %s",13,10,0
From 		db "from: %s",13,10,0
BodyText 		db 1024 dup(?)
Point 		db 13,10,".",13,10,0
qtxt 			db "quit",13,10,0
ServerName 	db 128 dup(?)

; msg mime-headers
msgMIME     	db "MIME-Version: 1.0",0
msgConType1	db "Content-Type: multipart/mixed;boundary=",34,"----=_TestMail_358",34,13,10,0
msgConType2	db "Content-Type: text/html;charset=windows-1251",13,10,0
msgConTran1	db "Content-Transfer-Encoding: 7bit",13,10,13,10,0
msgConTran2	db "Content-transfer-encoding: base64",13,10,0
msgConDisp  	db "Content-Disposition: attachment; filename=%s",13,10,13,10,0
msgBoundary	db 13,10,"------=_TestMail_358",13,10,0
msgEnd  		db 13,10,13,10,"------=_TestMail_358--",0
; message number, may be added to subject
MsgNum		dd 0
ErrNum		dd 0
strMsgNum	db "msgs: %d errors: %d",0
NumBuf		db 64 dup(0)
hStatusBar	dd 0 ; handle of status bar is placed here
; number of threads
ThreadNum	dw 1
strThreadNum	db "%d",0
ThrNumBuf	db 4 dup(0)
csec CRITICAL_SECTION <>
; delay
Delay		dd 0
strDelay		db "%d",0
DelayBuf		db 7 dup(0)

stoptxt		db "Stop",0
cycletxt		db "Cycle",0
flag			db 0

; counter 
Counter		dd 0
CountBuf		db 7 dup(0)

; for sockets
wsaData     WSADATA <0>
saServer    sockaddr_in <0>
sockaddrsz	 dd sizeof sockaddr_in
socktimeout	dd	5000

; logging
loglevel		db 00000001b
LogFileName	db ".\\crazy.log",0
hLogFile		dd 0
LogErrString	db "%s %s Thread %d: Error in %s: %X %s", 13, 10, 0
LogEvtString	db "%s %s %s", 13, 10, 0
strStart		db "Starting cycle message sending", 0
strEnd		db "Ending cycle message sending", 0
strThreadStart	db "Starting Thread %d", 0
strThreadEnd	db "Exit", 0
strThreadEvt	db "Thread %d: %s",0
;strAnswer		db "Answer is %s",0
strSending	db "Sending message %d",0
dThrNum		dd	0
; names of functions
strConnectHost db "ConnectHost( )",0
;strReceive	db "Receive( )",0
strHandShake	db "HandShake( )",0
strSendMsg	db "SendMsg( )",0
;strSendAtt	db "SendAtt( )",0
strSendQuit	db "SendQuit( )",0

; for file open dialog
ofn OPENFILENAME <0>
FilterString	db "All Files",0,"*.*",0,0
filebuffer		db 260 dup(0)
OpenTitle		db "Choose the file",0
pFile1		dd 0
szFile1		dd 0
pFile2		dd 0
szFile2		dd 0
pFile3		dd 0
szFile3		dd 0
file1			db 128 dup(0)
file2			db 128 dup(0)
file3			db 128 dup(0)
AttFlag		db 0
pFileRcpt		dd 0
szFileRcpt	dd 0
hMappedFile	dd 0
hFileRcpt		dd 0
pFileRcptCP	dd 0
; for menu item
mim MENUITEMINFO <>
mim2 MENUITEMINFO <>
mim3 MENUITEMINFO <>
miml MENUITEMINFO <>

; for DateTime
datim SYSTEMTIME <>

; for Tray
note NOTIFYICONDATA <>

.code
Program:

    
    invoke GetModuleHandle, NULL
    invoke DialogBoxParam, eax, TestDialog, NULL, addr DlgProc, NULL
    invoke ExitProcess, 0

DlgProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
;LOCAL lpLogBuf, lpEvtBuf, lpDate, lpTime:DWORD

     .if uMsg==WM_INITDIALOG
	invoke GetModuleHandle, NULL
	invoke LoadIcon, eax, testicon
	invoke SendMessage, hWin, WM_SETICON, ICON_SMALL, eax
     	call _initdialog

    .elseif uMsg==WM_VSCROLL
    	invoke SendDlgItemMessage, hWin, Spin, UDM_GETPOS, 0, 0
    	mov ThreadNum, ax
    	invoke  wsprintf, offset ThrNumBuf, offset strThreadNum, ThreadNum
     	invoke SetDlgItemText, hWin, ThreadsNum, offset ThrNumBuf
     	
    	invoke SendDlgItemMessage, hWin, SpinDelay, UDM_GETPOS32, 0, 0
    	mov Delay, eax
    	invoke  wsprintf, offset DelayBuf, offset strDelay, Delay
     	invoke SetDlgItemText, hWin, DelayVal, offset DelayBuf
     	
     .elseif uMsg==WM_SIZE
           .if wParam==SIZE_MINIMIZED
               mov note.cbSize,sizeof NOTIFYICONDATA
               push hWin
               pop note.hwnd

               mov note.uID,TRAY
               mov note.uFlags,NIF_ICON+NIF_MESSAGE+NIF_TIP
               mov note.uCallbackMessage,WM_SHELLNOTIFY
               invoke GetModuleHandle, NULL
               invoke LoadIcon, eax, testicon

               mov note.hIcon,eax
               invoke lstrcpy,addr note.szTip,addr NumBuf
               invoke ShowWindow,hWin,SW_HIDE
               invoke Shell_NotifyIcon,NIM_ADD,addr note

           .endif
	.elseif uMsg==WM_SHELLNOTIFY
           .if wParam==TRAY
           	invoke lstrcpy,addr note.szTip,addr NumBuf
               	invoke Shell_NotifyIcon,NIM_MODIFY,addr note
               .if lParam==WM_LBUTTONDBLCLK
                   invoke Shell_NotifyIcon,NIM_DELETE,addr note
                   invoke ShowWindow,hWin,SW_RESTORE
                   invoke SetForegroundWindow, hWin
               .endif
           .endif
           
    .elseif uMsg==WM_COMMAND
        mov eax,wParam
        mov edx,eax
        shr edx,16
        and eax,0FFFFh
        
        .if eax==Exit
            	invoke DeleteCriticalSection, offset csec
            	invoke EndDialog, hWin, NULL
            	
        .elseif eax==Load
        		call _loadsettings
        		
        .elseif eax==Save
        		call _savesettings
        		
        .elseif eax==AddtoSubj
        		invoke MnuAddToSubj,hWin
        		
        .elseif eax==AddDateTime
        		invoke MnuAddDateTime,hWin
        		
        .elseif eax==Nologs
        		invoke MnuLog,hWin,00000001b,Nologs,Logerrors,Fulllog

        .elseif eax==Logerrors
        		invoke MnuLog,hWin,00000010b,Logerrors,Fulllog,Nologs
        
        .elseif eax==Fulllog
        		invoke MnuLog,hWin,00000100b,Fulllog,Nologs,Logerrors
        
        .elseif eax==RcptFF
        		invoke MnuRcptFF,hWin
        		        		
        .elseif eax==DelayVal
        		.if edx==EN_CHANGE
        			invoke SendDlgItemMessage, hWin, DelayVal, WM_GETTEXT, 7, offset DelayBuf
        			mov ecx, offset DelayBuf
         			call atoi
         			mov Delay, eax
         			invoke SendDlgItemMessage, hWin, SpinDelay, UDM_SETPOS32, 0, eax
         		.endif
         		
	.elseif eax==CountVal
        		.if edx==EN_CHANGE
        			invoke SendDlgItemMessage, hWin, CountVal, WM_GETTEXT, 7, offset CountBuf
        			mov ecx, offset CountBuf
         			call atoi
         			mov Counter, eax
         		.endif
         		
        .elseif edx==BN_CLICKED
            	.if eax==Send
                		invoke BtnSend,hWin
                		
             	.elseif eax==Check
             		invoke GetDlgItem, hWin, Check
                		invoke EnableWindow, eax, FALSE 
             		invoke SendDlgItemMessage, hWin, ServerEdit, WM_GETTEXT, 128, offset ServerName
             		invoke CheckHost, hWin
             		invoke GetDlgItem, hWin, Check
                		invoke EnableWindow, eax, TRUE
                		
               	.elseif eax==Cycle
	         		invoke BtnCycle,hWin
	         		
	      .elseif eax==CountChk
	      		invoke GetDlgItem, hWin, CountChk
	      		invoke SendMessage, eax, BM_GETCHECK, 0, 0
	      		.if eax==BST_CHECKED
	      			invoke GetDlgItem, hWin, CountVal
	      			invoke EnableWindow, eax, TRUE
	      		.else
	      			invoke GetDlgItem, hWin, CountVal
	      			invoke EnableWindow, eax, FALSE
	      		.endif 
	
	      .elseif eax==Browse1
	      		invoke BtnBrowse,hWin,offset pFile1,offset szFile1,file_name1,offset file1
	      		
;	      		invoke wsprintf,offset file1,offset strSending, szFile1
;	      		invoke MessageBox,0,pFile1,offset file1,0
	      		
	      .elseif eax==Browse2
	      		invoke BtnBrowse,hWin,offset pFile2,offset szFile2,file_name2,offset file2
	      		
	      .elseif eax==Browse3
	      		invoke BtnBrowse,hWin,offset pFile3,offset szFile3,file_name3,offset file3
	      		
              .endif
        .endif
        
    .elseif uMsg==WM_CLOSE
	invoke DeleteCriticalSection, offset csec
	invoke EndDialog, hWin, NULL
        
    .else
    	invoke SendMessage, hStatusBar, SB_SETTEXT, SB_SIMPLEID, offset NumBuf
    	mov eax,FALSE
        ret
        
    .endif
    
    mov eax,TRUE
    ret
    
_savesettings:
; get text
	invoke SendDlgItemMessage, hWin, FromEdit, WM_GETTEXT, 128, offset FromText
	invoke SendDlgItemMessage, hWin, ToEdit, WM_GETTEXT, 128, offset ToText
	invoke SendDlgItemMessage, hWin, SubjEdit, WM_GETTEXT, 128, offset SubjText 
	invoke SendDlgItemMessage, hWin, BodyEdit, WM_GETTEXT, 1024, offset BodyText
	invoke SendDlgItemMessage, hWin, ServerEdit, WM_GETTEXT, 128, offset ServerName
; save settings to file
	invoke WritePrivateProfileString,offset lpAppName, offset lpFrom, offset FromText, offset IniFileName
	invoke WritePrivateProfileString, offset lpAppName, offset lpTo, offset ToText, offset IniFileName
	invoke WritePrivateProfileString, offset lpAppName, offset lpSubj, offset SubjText, offset IniFileName
	invoke WritePrivateProfileString, offset lpAppName, offset lpBody, offset BodyText, offset IniFileName
	invoke WritePrivateProfileString, offset lpAppName, offset lpServer, offset ServerName, offset IniFileName
	
_loadsettings:
; load settings from ini-file
	invoke GetPrivateProfileString,offset lpAppName, offset lpFrom, NULL, offset FromText, 128, offset IniFileName
	invoke GetPrivateProfileString, offset lpAppName, offset lpTo, NULL, offset ToText, 128, offset IniFileName
	invoke GetPrivateProfileString, offset lpAppName, offset lpSubj, NULL, offset SubjText, 128, offset IniFileName
	invoke GetPrivateProfileString, offset lpAppName, offset lpBody, NULL, offset BodyText, 1024, offset IniFileName
	invoke GetPrivateProfileString, offset lpAppName, offset lpServer, NULL, offset ServerName, 128, offset IniFileName
	 
; initialize text
	invoke SendDlgItemMessage, hWin, FromEdit, WM_SETTEXT, 128, offset FromText
	invoke SendDlgItemMessage, hWin, ToEdit, WM_SETTEXT, 128, offset ToText
	invoke SendDlgItemMessage, hWin, SubjEdit, WM_SETTEXT, 128, offset SubjText 
	invoke SendDlgItemMessage, hWin, BodyEdit, WM_SETTEXT, 1024, offset BodyText
	invoke SendDlgItemMessage, hWin, ServerEdit, WM_SETTEXT, 128, offset ServerName
	
	pop ecx
	jmp ecx
	
_initdialog:
	call _loadsettings
; save handle of status bar
     	invoke GetDlgItem, hWin, StatusBar
     	mov hStatusBar, eax
     	
; init edit and spin
     	invoke  wsprintf, offset ThrNumBuf, offset strThreadNum, ThreadNum
     	invoke SetDlgItemText, hWin, ThreadsNum, offset ThrNumBuf
     	invoke SendDlgItemMessage, hWin, Spin, UDM_SETRANGE, 0, 00010063h
     	
     	invoke  wsprintf, offset DelayBuf, offset strDelay, Delay
     	invoke SetDlgItemText, hWin, Delay, offset DelayBuf
     	invoke SendDlgItemMessage, hWin, SpinDelay, UDM_SETRANGE32, 0, 0000ffffh
     	
; init critical section
     	invoke InitializeCriticalSectionAndSpinCount, offset csec, 80000400h

	ret

; converts string to int
; input:	ecx = pointer to buffer with string
; output:	eax = result
atoi:          			xor ebx,ebx
                			xor eax,eax
                			xor edx,edx
_count:     			mov bl, byte ptr [ecx]
                			cmp bl, 0
                			je _fcount
                			sub ebx, 48
                			push eax
                			shl eax,3
                			pop edx
                			shl edx,1
                			add eax, edx
                			add eax, ebx
                			inc ecx
                			jmp _count
_fcount:    			pop ecx
                			jmp ecx

DlgProc endp

MnuAddToSubj proc hWin:HWND

        		mov mim.cbSize, sizeof MENUITEMINFO
        		mov mim.fMask, MIIM_STATE
        		invoke GetMenu, hWin 
        		invoke GetMenuItemInfo, eax, AddtoSubj, FALSE, offset mim
        		.if mim.fState==MFS_CHECKED
        			mov mim.fState, MFS_UNCHECKED
        		.else
        			mov mim.fState, MFS_CHECKED
        		.endif
        		invoke GetMenu, hWin
        		invoke SetMenuItemInfo, eax, AddtoSubj, FALSE, offset mim
        		
	Ret
MnuAddToSubj EndP

MnuAddDateTime proc hWin:HWND

        		mov mim2.cbSize, sizeof MENUITEMINFO
        		mov mim2.fMask, MIIM_STATE
        		invoke GetMenu, hWin 
        		invoke GetMenuItemInfo, eax, AddDateTime, FALSE, offset mim2
        		.if mim2.fState==MFS_CHECKED
        			mov mim2.fState, MFS_UNCHECKED
        		.else
        			mov mim2.fState, MFS_CHECKED
        		.endif
        		invoke GetMenu, hWin
        		invoke SetMenuItemInfo, eax, AddDateTime, FALSE, offset mim2

	Ret
MnuAddDateTime EndP

MnuLog proc hWin:HWND,setlevel:BYTE,checkitem:UINT,uncheckitem1:UINT,uncheckitem2:UINT

        		mov al, setlevel
        		cmp loglevel, al
        		je @f
        		.if hLogFile==0
        			invoke CreateFile,offset LogFileName, FILE_GENERIC_WRITE xor FILE_WRITE_DATA, FILE_SHARE_READ,NULL, OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
        			mov hLogFile, eax
        		.elseif al==00000001b
        			invoke CloseHandle, hLogFile
        			mov hLogFile, 0
        		.endif
        		mov al, setlevel        		
         		mov loglevel, al
        		mov miml.cbSize, sizeof MENUITEMINFO
        		mov miml.fMask, MIIM_STATE
        		mov miml.fState, MFS_CHECKED
        		invoke GetMenu, hWin
        		invoke SetMenuItemInfo, eax, checkitem, FALSE, offset miml
        		mov miml.fState, MFS_UNCHECKED
        		invoke GetMenu, hWin
        		invoke SetMenuItemInfo, eax, uncheckitem1, FALSE, offset miml
        		invoke GetMenu, hWin
        		invoke SetMenuItemInfo, eax, uncheckitem2, FALSE, offset miml
@@:

	Ret
MnuLog EndP

MnuRcptFF proc hWin:HWND

        		mov mim3.cbSize, sizeof MENUITEMINFO
        		mov mim3.fMask, MIIM_STATE
        		invoke GetMenu, hWin 
        		invoke GetMenuItemInfo, eax, RcptFF, FALSE, offset mim3
        		.if mim3.fState==MFS_CHECKED
        			mov mim3.fState, MFS_UNCHECKED
        			invoke GetPrivateProfileString, offset lpAppName, offset lpTo, NULL, offset ToText, 128, offset IniFileName
        			invoke SendDlgItemMessage, hWin, ToEdit, WM_SETTEXT, 128, offset ToText
        			invoke GetDlgItem, hWin, ToEdit
        			invoke EnableWindow, eax, TRUE
        		.else
        			invoke BrowseFile, hWin
        				.if eax==TRUE
        					mov mim3.fState, MFS_CHECKED
        					invoke UnmapViewOfFile,pFileRcpt
        					invoke CloseHandle,hMappedFile
        					invoke CloseHandle,hFileRcpt
        					invoke FileOpen
        					mov pFileRcpt, eax
        					mov szFileRcpt, ebx
        					mov hMappedFile, ecx
        					mov hFileRcpt, edx
        					mov esi, eax
        					mov edi, offset ToText
        					invoke GetEmail
        					jnc _willcontinue
        					mov esi, pFileRcpt
_willcontinue:			mov pFileRcptCP, esi 
        					invoke SendDlgItemMessage, hWin, ToEdit, WM_SETTEXT, 128, offset ToText
        					invoke GetDlgItem, hWin, ToEdit
        					invoke EnableWindow, eax, FALSE
        				.endif
        		.endif
        		invoke GetMenu, hWin
        		invoke SetMenuItemInfo, eax, RcptFF, FALSE, offset mim3

	Ret
MnuRcptFF EndP

BtnSend proc hWin:HWND

                		invoke GetDlgItem, hWin, Send
                		invoke EnableWindow, eax, FALSE
                		invoke SendDlgItemMessage, hWin, FromEdit, WM_GETTEXT, 128, offset FromText
                		invoke SendDlgItemMessage, hWin, ToEdit, WM_GETTEXT, 128, offset ToText
                		invoke SendDlgItemMessage, hWin, SubjEdit, WM_GETTEXT, 128, offset SubjText 
                		invoke SendDlgItemMessage, hWin, BodyEdit, WM_GETTEXT, 1024, offset BodyText
                		invoke SendDlgItemMessage, hWin, ServerEdit, WM_GETTEXT, 128, offset ServerName
                		mov dThrNum, 0
                		mov MsgNum, 0
                		mov ErrNum, 0
                		invoke InitData, hWin
                		invoke CreateThread, NULL, NULL, offset LoopMsg, hWin, 0, NULL
	         		invoke CloseHandle, eax
                		invoke GetDlgItem, hWin, Send
                		invoke EnableWindow, eax, TRUE

	Ret
BtnSend EndP

BtnCycle proc hWin:HWND
LOCAL lpLogBuf, lpEvtBuf, lpDate, lpTime:DWORD

	         			; allocate memory for logging local events
	         			invoke GlobalAlloc, GPTR, 512
	         			mov lpLogBuf, eax
	         			invoke GlobalAlloc, GPTR, 256
	         			mov lpEvtBuf, eax
	         			invoke GlobalAlloc, GPTR, 16
	         			mov lpDate, eax
	         			invoke GlobalAlloc, GPTR, 16
	         			mov lpTime, eax
	         		.if flag==0
	         			invoke SendDlgItemMessage, hWin, Cycle, WM_SETTEXT, 128, offset stoptxt
	         			invoke GetDlgItem, hWin, Send
	           		invoke EnableWindow, eax, FALSE
	           		invoke GetDlgItem, hWin, Browse1
	           		invoke EnableWindow, eax, FALSE
	           		invoke GetDlgItem, hWin, Browse2
	           		invoke EnableWindow, eax, FALSE
	           		invoke GetDlgItem, hWin, Browse3
	           		invoke EnableWindow, eax, FALSE
         				.if loglevel!=00000001b ; if error logging is enabled
         					invoke LogEvent, lpDate, lpTime, offset strStart, lpLogBuf
         				.endif
	          		invoke SendDlgItemMessage, hWin, FromEdit, WM_GETTEXT, 128, offset FromText
                			invoke SendDlgItemMessage, hWin, ToEdit, WM_GETTEXT, 128, offset ToText
                			invoke SendDlgItemMessage, hWin, SubjEdit, WM_GETTEXT, 128, offset SubjText 
                			invoke SendDlgItemMessage, hWin, BodyEdit, WM_GETTEXT, 1024, offset BodyText
                			invoke SendDlgItemMessage, hWin, ServerEdit, WM_GETTEXT, 128, offset ServerName
                			mov dThrNum, 0
                			mov MsgNum, 0
                			mov ErrNum, 0
	         			mov flag,1
	         			invoke InitData, hWin
	         			xor ebx,ebx
	         			mov bx, ThreadNum
	         			.while ebx!=0
	         				dec ebx
	         				push ebx
	         				.if loglevel==00000100b; if full logging enabled
	         					xor eax, eax
	         					mov ax, ThreadNum
	         					sub ax, bx
	         					invoke  wsprintf, lpEvtBuf, offset strThreadStart, eax
	         					invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
	         				.endif
	         				invoke CreateThread, NULL, NULL, offset LoopMsg, hWin, 0, NULL
	         				invoke CloseHandle, eax
	         				invoke Sleep, 100
	         				pop ebx
	         			.endw 
	         		.else
	         			mov flag,0
   			         	.if loglevel!=00000001b ; if error logging is enabled
         					invoke LogEvent, lpDate, lpTime, offset strEnd, lpLogBuf
         				.endif

	         			invoke SendDlgItemMessage, hWin, Cycle, WM_SETTEXT, 128, offset cycletxt
	         			invoke GetDlgItem, hWin, Send
	          		invoke EnableWindow, eax, TRUE
	          		invoke GetDlgItem, hWin, Browse1
	          		invoke EnableWindow, eax, TRUE
	          		invoke GetDlgItem, hWin, Browse2
	          		invoke EnableWindow, eax, TRUE
 				invoke GetDlgItem, hWin, Browse3
	          		invoke EnableWindow, eax, TRUE
	         		.endif
	          		; destroy memory for logging local events
          			invoke GlobalFree, lpDate
          			invoke GlobalFree, lpTime
          			invoke GlobalFree, lpEvtBuf
          			invoke GlobalFree, lpLogBuf

	Ret
BtnCycle EndP

BtnBrowse proc hWin:HWND,ppFile:DWORD,pszFile:DWORD,file_name:UINT,pFile:DWORD

invoke BrowseFile, hWin
.if eax==TRUE
	mov edi,ppFile
	invoke GlobalFree, [edi]
	invoke FileEnc
	mov edi, ppFile
	mov [edi], eax
	mov edi, pszFile
	mov [edi], ebx
	mov  eax,ofn.lpstrFile
	push ebx
	xor  ebx,ebx
	mov  bx,ofn.nFileOffset
	add  eax,ebx
	pop  ebx
	invoke SendDlgItemMessage, hWin, file_name, WM_SETTEXT, 128, eax
	mov eax, file_name
	sub eax,7
	invoke GetDlgItem, hWin, eax 
	invoke EnableWindow, eax, TRUE
	invoke SendDlgItemMessage, hWin, file_name, WM_GETTEXT, 128, pFile
.endif

	Ret
BtnBrowse EndP

ConnectHost proc lServerName:DWORD, port:DWORD ; returns opened socket in eax, eax=0 if error
	LOCAL hSocket, ErrorCode:DWORD
	
	; connect to socket
	invoke WSAStartup, 0101h, offset wsaData
	cmp  eax,0
    	jne  _CH_Exit
    	invoke  gethostbyname, lServerName
	cmp  eax,0
    	je  _CH_Exit
    	mov	eax, [eax+12]  ; get pointer to IP in HOSTENT
        	mov	eax, [eax]
        	mov	eax, [eax]
        	mov	saServer.sin_addr,eax
        	mov	saServer.sin_family,AF_INET
    	invoke htons, port
    	mov	saServer.sin_port,ax
        	invoke socket, AF_INET, SOCK_STREAM, IPPROTO_TCP ;open socket
        	cmp eax, INVALID_SOCKET
        	je _CH_Exit
        	mov hSocket, eax
        	; set timeout for socket
        	invoke setsockopt, hSocket, SOL_SOCKET, SO_RCVTIMEO, offset socktimeout, 4
        	cmp eax, SOCKET_ERROR
    	je  _CH_CloseSocket
        	invoke  connect, hSocket, offset saServer, sockaddrsz
    	cmp eax, SOCKET_ERROR
    	je  _CH_CloseSocket
    	mov eax, hSocket
    	Ret
    	
_CH_CloseSocket:
	invoke GetLastError
	mov ErrorCode, eax
	invoke closesocket, hSocket
	mov ebx, ErrorCode
	Ret
_CH_Exit:
	invoke GetLastError
	mov ErrorCode, eax
    	mov eax,0
    	mov ebx, ErrorCode
	Ret
ConnectHost EndP

HandShake proc hSocket:DWORD ; receives server invitation and sends "helo server", check eax, not " 052" means that socket was closed
LOCAL lBuf, ErrorCode:DWORD

    	; receive server invitation
    	invoke Receive, hSocket
    	cmp eax, SOCKET_ERROR
    	je  _HS_CloseSocket
    	cmp eax, " 022"
    	jne _HS_CloseSocket
    	
	; send "helo server"
	invoke lstrlen, offset helo
    	invoke send, hSocket, offset helo, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _HS_CloseSocket
    	; receive the answer
    	invoke Receive, hSocket
    	cmp eax, SOCKET_ERROR
    	je  _HS_CloseSocket
    	cmp eax, " 052"
    	jne _HS_CloseSocket
    	Ret
    	
_HS_CloseSocket:
	mov lBuf, eax
	invoke GetLastError
	mov ErrorCode, eax
	invoke closesocket, hSocket
    	mov eax,lBuf
    	mov ebx, ErrorCode
	Ret
HandShake EndP

SendQuit proc hSocket:DWORD ; sends QUIT and closes socket
LOCAL lBuf, ErrorCode:DWORD

	;send "quit"
    	invoke lstrlen, offset qtxt
    	invoke send, hSocket, offset qtxt, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SQ_CloseSocket
    	invoke Receive,hSocket
    	; disconnect from socket
_SQ_CloseSocket:
	mov lBuf, eax
	invoke GetLastError
	mov ErrorCode, eax
	invoke closesocket, hSocket
	mov eax, lBuf
	mov ebx, ErrorCode
	Ret
SendQuit EndP

Receive proc hSocket:DWORD ; returns first 4 received bytes in eax or SOCKET_ERROR
LOCAL lBuf:DWORD, lByte:BYTE

	invoke recv, hSocket, addr lBuf, 4, 0
    	cmp eax, SOCKET_ERROR
    	je  _retrcv
@@:
	invoke recv, hSocket, addr lByte, 1,0
	cmp eax, SOCKET_ERROR
    	je  _retrcv
	cmp lByte,0ah
	jne @b
	mov eax, lBuf
_retrcv:

	Ret
Receive EndP
SendMsg proc hSocket:DWORD, lMsgNum:DWORD, lpEmail:DWORD, lpbuf:DWORD, lpDate:DWORD, lpTime:DWORD ; check last answer in eax for SOCKET_ERROR, if it is then socket must be closed
LOCAL lpNext, lBuf, ErrorCode :DWORD

	invoke lstrcpy, lpEmail, offset FromText
    	invoke  wsprintf, lpbuf, offset MFrom, lpEmail
    	invoke lstrlen, lpbuf
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	invoke Receive, hSocket
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	cmp eax, " 052"
    	jne _SM_CloseSocket
    	
	; send "rcpt to:"
	mov eax, offset ToText
	mov lpNext, eax
_getrcpt:
	mov esi, lpNext
	mov edi, lpEmail
	xor ecx, ecx
@@:
	lodsb
	cmp al,','
	je @f
	cmp al,';'
	je @f
	cmp al,0
	je _endofstring
	stosb
	inc ecx
	jmp @b
_endofstring:
	dec esi
@@:
	cmp ecx, 0
	je @f
	mov byte ptr [edi],0
	mov lpNext, esi
	invoke  wsprintf, lpbuf, offset RTo, lpEmail
    	invoke lstrlen, lpbuf
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	invoke Receive, hSocket
	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	cmp eax, " 052"
    	jne _SM_CloseSocket
    	jmp _getrcpt
@@:   	
	; send "data"
    	invoke lstrlen, offset SData
    	invoke send, hSocket, offset SData, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	invoke Receive, hSocket
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	cmp eax, " 453"
    	jne _SM_CloseSocket
    	
    	; send message
    	; subject
    	invoke lstrcpy, lpEmail, offset SubjText
    	.if lMsgNum==0 
    		invoke  wsprintf, lpbuf, offset Subj, lpEmail
    		.if mim2.fState==MFS_CHECKED
    			invoke GetLocalTime, ADDR datim
    			invoke GetTimeFormat, LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, ADDR datim, NULL, lpTime, 16
    			invoke GetDateFormat, LOCALE_USER_DEFAULT, 0, ADDR datim, NULL, lpDate, 16
    			invoke  wsprintf, lpbuf, offset SubjDate, lpEmail, lpDate, lpTime
    		.endif 
    	.elseif mim.fState==MFS_CHECKED
    		.if mim2.fState==MFS_CHECKED
    			invoke GetLocalTime, ADDR datim
    			invoke GetTimeFormat, LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, ADDR datim, NULL, lpTime, 16
    			invoke GetDateFormat, LOCALE_USER_DEFAULT, 0, ADDR datim, NULL, lpDate, 16
    			invoke  wsprintf, lpbuf, offset SubjNum, lpEmail, lpDate, lpTime, lMsgNum
    		.else
    			invoke  wsprintf, lpbuf, offset SubjNum, lpEmail, 0, 0, lMsgNum
    		.endif
    	.else
    		.if mim2.fState==MFS_CHECKED
    			invoke GetLocalTime, ADDR datim
    			invoke GetTimeFormat, LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, ADDR datim, NULL, lpTime, 16
    			invoke GetDateFormat, LOCALE_USER_DEFAULT, 0, ADDR datim, NULL, lpDate, 16
    			invoke  wsprintf, lpbuf, offset SubjDate, lpEmail, lpDate, lpTime
    		.else
	    		invoke  wsprintf, lpbuf, offset Subj, lpEmail
	    	.endif
    	.endif
    	invoke lstrlen, lpbuf
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; to
    	invoke lstrcpy, lpEmail, offset ToText
    	invoke  wsprintf, lpbuf, offset To, lpEmail
    	invoke lstrlen, lpbuf 
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; from
    	invoke lstrcpy, lpEmail, offset FromText
    	invoke  wsprintf, lpbuf, offset From, lpEmail
    	invoke lstrlen, lpbuf 
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; send msgConType1
    	invoke lstrlen, offset msgConType1
    	invoke send, hSocket, offset msgConType1, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; send msgBoundary
    	invoke lstrlen, offset msgBoundary
    	invoke send, hSocket, offset msgBoundary, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; send msgConType2
    	invoke lstrlen, offset msgConType2
    	invoke send, hSocket, offset msgConType2, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; send msgConTran1
    	invoke lstrlen, offset msgConTran1
    	invoke send, hSocket, offset msgConTran1, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; body
    	invoke lstrlen, offset BodyText
    	invoke send, hSocket, offset BodyText, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; send Attachments
    	invoke SendAtt, hSocket, lpbuf
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	; send msgEnd
    	invoke lstrlen, offset msgEnd
    	invoke send, hSocket, offset msgEnd, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	;send Point
    	invoke send, hSocket, offset Point, 5, 0
    	cmp eax, SOCKET_ERROR
    	je  _SM_CloseSocket
    	invoke Receive,hSocket
    	Ret
_SM_CloseSocket:
	mov lBuf, eax
	invoke GetLastError
	mov ErrorCode, eax
    	mov eax, lBuf
	mov ebx, ErrorCode
	Ret
SendMsg EndP

CheckHost proc hWin:HWND

	invoke WSAStartup, 0101h, offset wsaData
	cmp  eax,0
    	jne  _ChH_Exit
    	invoke  gethostbyname,offset ServerName
	cmp  eax,0
    	je  _ChH_Exit
    	mov	eax, [eax+12]  ; get pointer to IP in HOSTENT
        	mov	eax, [eax]
        	mov	eax, [eax]
        	invoke inet_ntoa, eax
        	invoke SendDlgItemMessage, hWin, IP_check, WM_SETTEXT, 128, eax
          
_ChH_Exit:  
  	invoke  WSACleanup
  	
	Ret
CheckHost EndP

WriteToLog proc lpLogBuf:DWORD
LOCAL szWritten:DWORD
	invoke lstrlen, lpLogBuf
	lea ebx, szWritten
	invoke WriteFile, hLogFile, lpLogBuf, eax, ebx, NULL
	Ret
WriteToLog EndP

LogError proc lpDate:DWORD, lpTime:DWORD, lpFuncName:DWORD, ErrorCode:DWORD, lpLogBuf:DWORD, lThrNum:DWORD
LOCAL lpErrBuf:DWORD
	invoke FormatMessage,FORMAT_MESSAGE_ALLOCATE_BUFFER or \
	FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,\
		NULL, ErrorCode, 0, addr lpErrBuf, 0, NULL
		invoke GetLocalTime, ADDR datim
	invoke GetTimeFormat, LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, ADDR datim, NULL, lpTime, 16
	invoke GetDateFormat, LOCALE_USER_DEFAULT, 0, ADDR datim, NULL, lpDate, 16
	invoke  wsprintf, lpLogBuf, offset LogErrString, lpDate, lpTime, lThrNum, lpFuncName, ErrorCode, lpErrBuf
	invoke WriteToLog, lpLogBuf
	invoke LocalFree, lpErrBuf	
	Ret
LogError EndP

LogEvent proc lpDate:DWORD, lpTime:DWORD, lpEvtBuf:DWORD, lpLogBuf:DWORD

	invoke GetLocalTime, ADDR datim
	invoke GetTimeFormat, LOCALE_USER_DEFAULT, TIME_FORCE24HOURFORMAT, ADDR datim, NULL, lpTime, 16
	invoke GetDateFormat, LOCALE_USER_DEFAULT, 0, ADDR datim, NULL, lpDate, 16
	invoke  wsprintf, lpLogBuf, offset LogEvtString, lpDate, lpTime, lpEvtBuf
	invoke WriteToLog, lpLogBuf
	Ret
LogEvent EndP

LoopMsg proc	hWin:HWND
LOCAL lThrNum, lMsgNum, lpEmail, lpbuf, lpDate, lpTime, hSocket, SockState, lpLogBuf, lpEvtBuf, ErrorCode, lpFuncName:DWORD

	invoke EnterCriticalSection, offset csec
		inc dThrNum
		mov eax, dThrNum
		mov lThrNum, eax
	invoke LeaveCriticalSection, offset csec

	invoke GlobalAlloc, GPTR, 128
	mov lpEmail, eax
	invoke GlobalAlloc, GPTR, 256
    	mov lpbuf, eax
	invoke GlobalAlloc, GPTR, 16
    	mov lpDate, eax
    	invoke GlobalAlloc, GPTR, 16
    	mov lpTime, eax
    	invoke GlobalAlloc, GPTR, 512
    	mov lpLogBuf, eax
    	invoke GlobalAlloc, GPTR, 256
    	mov lpEvtBuf, eax
    	
_LM_begin:
	.if loglevel==00000100b; if full logging enabled
		invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, offset strConnectHost
		invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
	.endif
    	invoke ConnectHost, offset ServerName, 25
    	cmp eax,0
    	mov lpFuncName, offset strConnectHost
    	mov ErrorCode, ebx
    	je _LM_Error
    	mov hSocket, eax
	.if loglevel==00000100b; if full logging enabled
		invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, offset strHandShake
		invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
	.endif
    	invoke HandShake, hSocket
;	.if loglevel==00000100b; if full logging enabled
;		push eax
;		invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, offset strAnswer
;		invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
;		pop eax
;	.endif
    	cmp eax, " 052"
    	mov lpFuncName, offset strHandShake
    	mov ErrorCode, ebx
    	jne _LM_Error

@@:
	invoke EnterCriticalSection, offset csec
		.if flag==1
			inc MsgNum
		.endif
		mov eax, MsgNum
		mov lMsgNum, eax
		mov al, AttFlag
		and al, 10000000b
		cmp al, 10000000b
		jne _cloop
		mov eax, Counter
		cmp lMsgNum, eax
		jbe _cloop
		mov flag, 0
		invoke SendDlgItemMessage, hWin, Cycle, WM_SETTEXT, 128, offset cycletxt
	         	invoke GetDlgItem, hWin, Send
	         	invoke EnableWindow, eax, TRUE
	         	invoke GetDlgItem, hWin, Browse1
	         	invoke EnableWindow, eax, TRUE
	         	invoke GetDlgItem, hWin, Browse2
	         	invoke EnableWindow, eax, TRUE
 		invoke GetDlgItem, hWin, Browse3
	         	invoke EnableWindow, eax, TRUE
	         	dec MsgNum
_cloop:
		invoke  wsprintf, offset NumBuf, offset strMsgNum, MsgNum, ErrNum
		invoke SendMessage, hStatusBar, SB_SETTEXT, SB_SIMPLEID, offset NumBuf
	invoke LeaveCriticalSection, offset csec
	.if flag==1
		.if loglevel==00000100b; if full logging enabled
			invoke wsprintf, lpbuf, offset strSending, lMsgNum
			invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, lpbuf
			invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
		.endif
		.if mim3.fState==MFS_CHECKED ; case when recepients are taken from file
			invoke EnterCriticalSection, offset csec
				invoke SendMsg, hSocket, lMsgNum, lpEmail, lpbuf, lpDate, lpTime
				mov SockState, eax
				mov ErrorCode, ebx
				mov edi, offset ToText
				mov esi, pFileRcptCP
				invoke GetEmail
				jnc _willcont1
				mov esi, pFileRcpt
		_willcont1:
				mov pFileRcptCP, esi
				invoke SendDlgItemMessage, hWin, ToEdit, WM_SETTEXT, 128, offset ToText
			invoke LeaveCriticalSection, offset csec
		.else
			invoke SendMsg, hSocket, lMsgNum, lpEmail, lpbuf, lpDate, lpTime
			mov SockState, eax
			mov ErrorCode, ebx
		.endif
		invoke Sleep, Delay
		mov eax, SockState
		cmp eax, SOCKET_ERROR
		jne @b ; continue sending messages
		invoke closesocket, hSocket
		invoke WSACleanup
		invoke EnterCriticalSection, offset csec
			inc ErrNum
			invoke  wsprintf, offset NumBuf, offset strMsgNum, MsgNum, ErrNum
		invoke LeaveCriticalSection, offset csec
		.if loglevel!=00000001b ; if error logging is enabled
			mov lpFuncName, offset strSendMsg
			invoke LogError, lpDate, lpTime, lpFuncName, ErrorCode, lpLogBuf, lThrNum
		.endif
		jmp _LM_begin ; establish new connection to host after closing socket
	.elseif lMsgNum ==0
		mov MsgNum, 0
		.if loglevel==00000100b; if full logging enabled
			invoke wsprintf, lpbuf, offset strSending, 1
			invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, lpbuf
			invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
		.endif
		.if mim3.fState==MFS_CHECKED ; case when recepients are taken from file
;			invoke EnterCriticalSection, offset csec
				invoke SendMsg, hSocket, lMsgNum, lpEmail, lpbuf, lpDate, lpTime
				mov SockState, eax
				mov ErrorCode, ebx
				mov edi, offset ToText
				mov esi, pFileRcptCP
				invoke GetEmail
				jnc @f
				mov esi, pFileRcpt
		@@:
				mov pFileRcptCP, esi
				invoke SendDlgItemMessage, hWin, ToEdit, WM_SETTEXT, 128, offset ToText
;			invoke LeaveCriticalSection, offset csec
		.else
			invoke SendMsg, hSocket, lMsgNum, lpEmail, lpbuf, lpDate, lpTime
			mov SockState, eax
			mov ErrorCode, ebx
		.endif
		cmp SockState, SOCKET_ERROR; if error AND error logging is enabled
		mov lpFuncName, offset strSendMsg
		je _LM_Error
	.endif

	.if loglevel==00000100b; if full logging enabled
		invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, offset strSendQuit
		invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
	.endif
	invoke SendQuit, hSocket
	mov lpFuncName, offset strSendQuit
	mov ErrorCode, ebx
	cmp eax, SOCKET_ERROR
	je _LM_Error
	invoke WSACleanup

	.if loglevel==00000100b; if full logging enabled
		invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, offset strThreadEnd
		invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
	.endif
	
	invoke GlobalFree, lpbuf
    	invoke GlobalFree, lpEmail
    	invoke GlobalFree, lpDate
    	invoke GlobalFree, lpTime
    	invoke GlobalFree, lpLogBuf
    	
    	Ret
	
_LM_Error:
	invoke EnterCriticalSection, offset csec
		inc ErrNum
		invoke  wsprintf, offset NumBuf, offset strMsgNum, MsgNum, ErrNum
	invoke LeaveCriticalSection, offset csec
	.if loglevel!=00000001b ; if error logging is enabled
		invoke LogError, lpDate, lpTime, lpFuncName, ErrorCode, lpLogBuf, lThrNum
	.endif
	invoke WSACleanup

	.if loglevel==00000100b; if full logging enabled
		invoke wsprintf, lpEvtBuf, offset strThreadEvt, lThrNum, offset strThreadEnd
		invoke LogEvent, lpDate, lpTime, lpEvtBuf, lpLogBuf
	.endif
	
	invoke GlobalFree, lpbuf
    	invoke GlobalFree, lpEmail
    	invoke GlobalFree, lpDate
    	invoke GlobalFree, lpTime
    	invoke GlobalFree, lpLogBuf
    	invoke GlobalFree, lpEvtBuf

	Ret
LoopMsg EndP

BrowseFile proc hWin:HWND;, Flags:DWORD
LOCAL lpCurDir:DWORD
	   mov ofn.lStructSize,SIZEOF ofn
            push hWin
            pop  ofn.hWndOwner
            mov  ofn.lpstrFilter, OFFSET FilterString
            mov  ofn.lpstrFile, OFFSET filebuffer
            mov  ofn.nMaxFile, 260
            mov  ofn.Flags, OFN_FILEMUSTEXIST or \
                       OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
                       OFN_EXPLORER or OFN_HIDEREADONLY
            mov  ofn.lpstrTitle, OFFSET OpenTitle
            invoke LocalAlloc, LPTR, 256
            mov lpCurDir, eax
            invoke GetCurrentDirectory, 256, lpCurDir
            invoke GetOpenFileName, ADDR ofn
            push eax
            invoke SetCurrentDirectory, lpCurDir
            invoke LocalFree, lpCurDir
            pop eax

	Ret
BrowseFile EndP

FileOpen proc ; opens file described in ofn structure, returns: eax = pointer to mapped view of file, ebx = size of file, ecx = handle of file mapping object, edx = file handle
LOCAL SizeR:DWORD
LOCAL fileHandle:HANDLE
LOCAL hMapFile:HANDLE

	invoke CreateFile,[ofn.lpstrFile],GENERIC_READ,FILE_SHARE_READ,NULL, OPEN_ALWAYS,FILE_FLAG_NO_BUFFERING,0
	mov fileHandle,eax
	invoke GetFileSize,fileHandle,NULL
	mov SizeR,eax
	invoke CreateFileMapping,fileHandle,NULL,PAGE_READONLY,0,SizeR,NULL
	mov hMapFile,eax
	invoke MapViewOfFile,hMapFile,FILE_MAP_READ,0,0,SizeR
	mov ebx,SizeR
	mov ecx, hMapFile

	Ret
FileOpen EndP

FileEnc proc ; returns: eax = pointer ro encrypted data, ebx = size of encrypted data
LOCAL SizeR:DWORD
LOCAL SizeW:DWORD
LOCAL fileHandle:HANDLE
LOCAL hMapFile:HANDLE
LOCAL pMemory:DWORD
LOCAL new_fileHandle:HANDLE
LOCAL new_hMapFile:HANDLE
LOCAL new_pMemory:DWORD
    
    invoke CreateFile,[ofn.lpstrFile],GENERIC_READ,FILE_SHARE_READ,NULL,\
            OPEN_EXISTING,FILE_FLAG_NO_BUFFERING,0
    mov fileHandle,eax
    invoke GetFileSize,fileHandle,NULL
    mov SizeR,eax
    xor edx,edx
    mov ecx,3
    div ecx
    or edx,edx
    jz @f
    inc eax
@@:
    shl eax,2
    mov SizeW,eax
    
    invoke CreateFileMapping,fileHandle,NULL,PAGE_READONLY,0,SizeR,NULL
    mov hMapFile,eax
    invoke MapViewOfFile,hMapFile,FILE_MAP_READ,0,0,SizeR
    mov pMemory,eax

    invoke GlobalAlloc, GPTR, SizeW
    mov new_pMemory,eax
    
    invoke b64_encode,pMemory,eax,SizeR
    
    invoke UnmapViewOfFile,pMemory
    invoke CloseHandle,hMapFile
    invoke CloseHandle,fileHandle
    
    mov eax,new_pMemory
    mov ebx,SizeW
    ret
FileEnc endp

b64_encode proc uses esi edi str_in:DWORD,str_out:DWORD,str_len:DWORD
     mov esi,str_in
     mov edi,str_out
     mov ecx,str_len
     or ecx,ecx
     jz @R
     cld
@L:  lodsb
     dec ecx
     or ecx,ecx
     jz @E
     mov ah,[esi]
     inc esi
     mov dx,ax
     shr al,2
     shl dl,4
     and dl,3Fh
     shr ah,4
     or ah,dl
     stosw      ; 1st and 2nd bytes
     dec ecx
     or ecx,ecx
     jz @E2
     lodsb
     mov dl,al
     shr al,6
     shl dh,2
     and dh,3Fh
     or al,dh
     mov ah,dl
     and ah,3Fh
     stosw      ; 3rd and 4th bytes
     loop @L
@@:  xor ax,ax
     jmp @fix
@E2: xor dl,dl	; zero instead of lacking byte
     shr al,6
     shl dh,2
     and dh,3Fh
     or al,dh
     mov ah,dl
     and ah,3Fh
     jmp @fix
@E:  xor ah,ah ; zero instead of lacking byte
     mov dx,ax
     shr al,2
     shl dl,4
     and dl,3Fh
     shr ah,4
     or ah,dl
@fix:
     stosw
     mov BYTE PTR [edi],0
     sub esi,str_in
     inc esi    ; ESI = lstrlen(str_in) + 2
     xchg eax,esi
     mov edx,0AAAAAAABh
     mul edx
     shl edx,1  ; EDX = ((lstrlen(str_in) + 2)/3)*4
     mov esi,str_out
     mov edi,esi
     ; convert to ASCII
@I:  lodsb
     cmp al,26
     jl @i1
     cmp al,52
     jl @i2
     cmp al,62
     jl @i3
     je @i4
     mov al,'/'
     jmp @F
@i1: add al,'A'
     jmp @F
@i2: add al,'a' - 26
     jmp @F
@i3: add al,'0' - 52
     jmp @F
@i4: mov al,'+'
@@:  stosb
     dec edx
     jnz @I
     xor edx,edx
     mov eax, str_len
     mov edi, 3
     div edi
     test edx,edx
     jbe @R
     sub edi, edx
     xchg eax,edx
     shl edx,2
     add edx,eax        ;EDX = (lstrlen(str_in)/3)*4 + remainder of division
     add edx,str_out
     test edi,edi
     jbe @R
@@:
     inc edx
     mov BYTE ptr [edx],'='
     dec edi
     jnz @B
@R:
     ret
b64_encode endp

InitData proc hWin:HWND

	invoke GetDlgItem, hWin, fileatt1
	invoke SendMessage, eax, BM_GETCHECK, 0, 0
	.if eax==BST_CHECKED
		or AttFlag, 00000001b
	.else
		and AttFlag, 11111110b
	.endif 
	invoke GetDlgItem, hWin, fileatt2
	invoke SendMessage, eax, BM_GETCHECK, 0, 0
	.if eax==BST_CHECKED
		or AttFlag, 00000010b
	.else
		and AttFlag, 11111101b
	.endif
	invoke GetDlgItem, hWin, fileatt3
	invoke SendMessage, eax, BM_GETCHECK, 0, 0
	.if eax==BST_CHECKED
		or AttFlag, 00000100b
	.else
		and AttFlag, 11111011b
	.endif
	invoke GetDlgItem, hWin, CountChk
	invoke SendMessage, eax, BM_GETCHECK, 0, 0
	.if eax==BST_CHECKED
		or AttFlag, 10000000b
	.else
		and AttFlag, 01111111b
	.endif
	mov mim.cbSize, sizeof MENUITEMINFO
        	mov mim.fMask, MIIM_STATE
	invoke GetMenu, hWin 
        	invoke GetMenuItemInfo, eax, AddtoSubj, FALSE, offset mim
        	
	Ret
InitData EndP

SendAtt proc hSocket:DWORD, lpbuf:DWORD

	mov al, AttFlag
	and al, 00000001b
	cmp al, 00000001b
	jne _send2
	; send msgBoundary
    	invoke lstrlen, offset msgBoundary
    	invoke send, hSocket, offset msgBoundary, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send msgConTran2
    	invoke lstrlen, offset msgConTran2
    	invoke send, hSocket, offset msgConTran2, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send msgConDisp
    	invoke  wsprintf, lpbuf, offset msgConDisp, offset file1
    	invoke lstrlen, lpbuf
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send EncData
    	invoke send, hSocket, pFile1, szFile1,0
    	cmp eax, SOCKET_ERROR
    	je  @f
_send2:
	mov al, AttFlag
	and al, 00000010b
	cmp al, 00000010b
	jne _send3
    	; send msgBoundary
    	invoke lstrlen, offset msgBoundary
    	invoke send, hSocket, offset msgBoundary, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send msgConTran2
    	invoke lstrlen, offset msgConTran2
    	invoke send, hSocket, offset msgConTran2, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send msgConDisp
    	invoke  wsprintf, lpbuf, offset msgConDisp, offset file2
    	invoke lstrlen, lpbuf
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send EncData
    	invoke send, hSocket, pFile2, szFile2,0
	cmp eax, SOCKET_ERROR
    	je  @f
_send3:
	mov al, AttFlag
	and al, 00000100b
	cmp al, 00000100b
	jne @f
    	; send msgBoundary
    	invoke lstrlen, offset msgBoundary
    	invoke send, hSocket, offset msgBoundary, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send msgConTran2
    	invoke lstrlen, offset msgConTran2
    	invoke send, hSocket, offset msgConTran2, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send msgConDisp
    	invoke  wsprintf, lpbuf, offset msgConDisp, offset file3
    	invoke lstrlen, lpbuf
    	invoke send, hSocket, lpbuf, eax, 0
    	cmp eax, SOCKET_ERROR
    	je  @f
    	; send EncData
    	invoke send, hSocket, pFile3, szFile3,0

@@:	
	Ret
SendAtt EndP

GetEmail proc ; input: esi = pointer to mem with emails, output: edi = pointer to mem with copied email, esi = current position 

	cmp byte ptr[esi], 0
	je _notfound
_ccopy:
	mov eax, pFileRcpt
	add eax, szFileRcpt
	cmp esi, eax
	ja _endoffile
	lodsb
	cmp al, 0
	je _endofmail
	cmp al, 13
	je _endofmail
	cmp al, 10
	je _endofmail
	stosb
	jmp _ccopy
_endofmail:
	mov eax, pFileRcpt
	add eax, szFileRcpt
	cmp esi, eax
	ja _endoffile
	lodsb
	cmp al, 0
	je _endofmail
	cmp al, 13
	je _endofmail
	cmp al, 10
	je _endofmail
	dec esi
	mov byte ptr [edi], 0
_notfound:
	clc
	ret
_endoffile:
	mov byte ptr [edi], 0
	stc
	Ret
GetEmail EndP

End Program