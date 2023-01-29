;** Fuzix Kernel Patch for Model 4p - (c) 2020 GmEsoft, All rights reserved. **
;
;	Fixes 2 bugs:
;	- video pages were swapped;
;	- missing wait ready loop after OTIR in hard disk I/O routine
;
;	Thu Dec 17 2020		Initial


;=====	Patch activation flags
$PCRTC	EQU	0			;Disable CRTC initialization
$PRAM94	EQU	0			;Disable Port 94 RAM expansion
$PVPAGE	EQU	1			;Fix Video Page Bug (mandatory)
$PSRINT	EQU	0			;Disable serial interrupts (if defective UART)
$P1HARD	EQU	0			;Use only 1 hard drive
$PWOTIR	EQU	1			;Fix missing wait ready loop after OTIR (mandatory on real machines)


;=====	original kernel binary
	ORG	0100H

	INCBIN	trs80-0.3.sys.bin	;original boot sector

;=====	patches
;-----	skip CRTC initialization
	IF	$PCRTC
	ORG	0167H			;skip CRTC initialization (@0167H)
	JR	$+11H
	NOP
	ENDIF

;-----	skip RAM expansion (port 94)
	IF	$PRAM94
	ORG	0AECCH			;skip RAM expansion (detect94 @AEC8H)
	JR	$+34H			;replaces JR Z,...

	ORG	0AF2BH			;mask out port 94H value
	AND	0			;replaces AND 1FH

	ORG	0AF47H			;mask out port 94H value
	AND	0			;replaces AND 1FH
	ENDIF

;-----	fix video page
	IF	$PVPAGE
	ORG	0AEC6H			;fix video page (..... @AEC6H)
	DB	86H			;OPREG = 86H instead of 06H
	ENDIF

;-----	disable serial int (defective UART)
	IF	$PSRINT
	ORG	0159H
	LD	A,04H			;disable serial int (..... @015A ..... @01A3)

	ORG	01A2H
	LD	A,04H			;disable serial int (..... @015A ..... @01A3)
	ENDIF

;-----	Use only 1 hard disk instead of 4
	IF	$P1HARD
	ORG	0B4DH			;Use only 1 hard disk instead of 4
	LD	A,0			;(NB: old value is 4 instead of 3 = BUG!!)

	ORG	0C278H			;Use only 1 hard disk instead of 4
	SUB	01H
	ENDIF

;-----	Add wait ready after OTIR
	IF	$PWOTIR			;

	ORG	0AEC0H
	CALL	ENDOTIR+0EDAFH-0B0F2H	;intercept map_kernel call after OTIR

	ORG	0B0A2H			;reorder PUSH statements in interrupt handler
	PUSH	BC
	PUSH	DE
	PUSH	IX
	PUSH	IY
	PUSH	AF			;push AF and HL last to pop them first
	PUSH	HL

	ORG	0B0F6H			;reorder POP statements and use dup code
	POP	HL			;pop HL and AF first
	POP	AF
	JP	0ECE3H			;then jump to common POP code

ENDOTIR	EX	(SP),HL			;additional wait ready loop after OTIR
	EX	(SP),HL
	IN	A,(0CFH)		;read HDD controller status
	RLCA
	JR	C,ENDOTIR		;loop while busy
	JP	0EBC2H			;reset memory map (map_kernel)

	ENDIF


	END
