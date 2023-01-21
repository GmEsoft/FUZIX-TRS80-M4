;** Fuzix Hard Disk Boot Sector - (c) 2020-23 GmEsoft, All rights reserved. **
;
;	Thu Dec 17 2022		Initial
;	Sat Jan 21, 2023	Fixed missing DI preventing from booting
;				from Model 4 with FreHD

CLSLEN	EQU	07FFH
M4BOOT	EQU	4300H
STACK	EQU	0EE00H
M4VID	EQU	0F800H
M4VID01	EQU	0F801H
M4VID50	EQU	0F850H

SYSCYL	EQU	202		;Cylinder holding the kernel binary

	ORG	0000H

	INCBIN	trs80-0.3.hdboot.bin	;original boot sector

	ORG	0000H

	;entry point 4300H - move to page 0
BOOT	DI			;Required when booting from M4+FreHD!
	LD	A,86H		;OPREG = 80x24 video, memory map 2
	OUT	(84H),A		;  KI and DO mapped in high memory
	LD	A,50H		;MODOUT = Fast, Enable ext I/O
	OUT	(0ECH),A	;
	LD	HL,M4BOOT	;Boot sector address in memory
	LD	D,L		;entry point 4300H - move to page 0
	LD	E,L		;
	LD	BC,ORIGIN	;Boot sector length = system origin
	LDIR			;Copy
	JP	BOOT1		;entry point after move to page 0

	;CRTC initilization data (registers 01 to 0F; 00 not written)
	DB	    50H,55H,0AH
	DB	19H,04H,18H,18H
	DB	00H,09H,65H,09H
	DB	00H,00H,00H,00H
	;CRTC registers values end
CRTC$	EQU	$-1

	;entry point after move to page 0
BOOT1	LD	SP,STACK

	;load CRTC registers
	LD	HL,CRTC$	;CRTC registers values last byte
	LD	BC,0F88H	;B=CRTC register - C=CRTC address port
LCRTC	OUT	(C),B		;select register
	LD	A,(HL)		;load register value from table
	OUT	(89H),A		;send value to CRTC register
	DEC	HL		;previous byte in table
	DJNZ	LCRTC		;repeat until CRTC register #1

	LD	HL,'LD'		;"LD" = loading
	LD	(M4VID+4EH),HL	;on screen

	EX	DE,HL		;HL = ORIGIN
	PUSH	HL		;push ret address

	LD	DE,0C601H	;D = #sectors; E = sector
;	LD	DE,0C701H	;D = #sectors; E = sector
	LD	BC,00C8H	;B = sec length (256); C = HDC data

	XOR	A		;init HDC Drive & Head
	EX	AF,AF'		;save

	;loop on 256-bytes blocks
LBLOCKS	EX	AF,AF'		;
	OUT	(0CEH),A	;HDC Drive & Head
	EX	AF,AF'		;
	LD	A,SYSCYL	;Cyl 1
	OUT	(0CCH),A	;
	LD	A,E		;Sector #
	OUT	(0CBH),A	;HDC Sector
	LD	A,20H		;HDC Cmd: READ
	OUT	(0CFH),A	;HDC Command
	EX	(SP),HL		;
	EX	(SP),HL		;
WAIT3	IN	A,(0CFH)	;Wait HDC status: !BSY
	RLCA			;
	JR	C,WAIT3		;
	IN	A,(0CFH)	;Get HDC status
	AND	01H		;Check ERR
	JR	NZ,ERROR	;Boot Load failed if yes
	INIR			;read sector into memory
	INC	E		;bump sector #
	LD	A,E		;end of track ?
	CP	21H		;
	JR	NZ,SAMETRK	;if not, stay on same track
	EX	AF,AF'		;
	INC	A		;increment head counter
	EX	AF,AF'		;
	LD	E,1		;
	;stay on same track
SAMETRK	DEC	D		;next 256-bytes block
	JR	NZ,LBLOCKS	;loop

	LD	HL,'BT'		;"BT" = booting
	LD	(M4VID+4EH),HL	;on screen
	RET			;Transfer to origin

ERROR	LD	HL,'ER'		;"ER" = error
ABEND	LD	(M4VID+4EH),HL	;on screen
	HALT			;stop

	ORG	0100H
	;system origin
ORIGIN	EQU	$

	END	BOOT

