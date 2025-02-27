;** Fuzix Kernel Patch for Model 4p - (c) 2020 GmEsoft, All rights reserved. **
;
;	Fixes 2 bugs:
;	- video pages were swapped;
;	- missing wait ready loop after OTIR in hard disk I/O routine
;
;	Thu Dec 17 2020		Initial


;=====	Patch activation flags
$PVPAGE	EQU	1			;Fix Video Page Bug (MANDATORY)
$PSRINT	EQU	1			;Disable serial interrupts (if defective UART)
$PWOTIR	EQU	1			;Fix missing wait ready loop after OTIR (MANDATORY on real machines)


;=====	original kernel binary
	ORG	0100H

	INCBIN	trs80-0.3.sys.bin	;original kernel binary

;=====	patches
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

;-----	Add wait ready after OTIR
	IF	$PWOTIR			;

ZOFFSET	EQU	0EDAFH-0B0F2H		;(=3CBD) phased block offset

	ORG	0EB7DH-ZOFFSET
	CALL	ENDOTIR+ZOFFSET		;intercept map_kernel call after OTIR

	ORG	0ED5FH-ZOFFSET		;reorder PUSH statements in interrupt handler
	PUSH	BC
	PUSH	DE
	PUSH	IX
	PUSH	IY
	PUSH	AF			;push AF and HL last to pop them first
	PUSH	HL

	ORG	0EDB3H-ZOFFSET		;(=B0F6) reorder POP statements and use dup code
	POP	HL			;pop HL and AF first
	POP	AF
	JP	0ECE3H			;(=B026) then jump to common POP code

ENDOTIR	EX	(SP),HL			;additional wait ready loop after OTIR
	EX	(SP),HL
	IN	A,(0CFH)		;read HDD controller status
	RLCA
	JR	C,ENDOTIR		;loop while busy
	JP	0EBC2H			;(=AF05) reset memory map (map_kernel)

	ENDIF

	END
